# frozen_string_literal: true

# Controller for quick mode bracket (choosing winners directly)
class QuickBracketsController < ApplicationController
  before_action :load_simulation
  before_action :ensure_quick_mode

  def show
    @qualification = KnockoutQualification.new(simulation: @simulation).call

    # Generate bracket if group stage is complete
    if @qualification[:qualifying_third_groups].length == 8
      KnockoutBracketGenerator.new(simulation: @simulation).generate
      KnockoutProgression.new(simulation: @simulation).update_bracket
    end

    @knockout_matches = Match.knockout
                             .includes(:home_team, :away_team)
                             .order(:match_number)

    @matches_by_round = @knockout_matches.group_by(&:round)

    @predictions = Prediction.where(simulation: @simulation, match: @knockout_matches)
                             .index_by(&:match_id)
  end

  # Choose third place teams that qualify
  def third_place
    # Check if all groups are complete
    unless all_groups_complete?
      redirect_to simulation_path(token: @simulation.token),
                  alert: t('flash.complete_groups_first')
      return
    end

    @qualification = KnockoutQualification.new(simulation: @simulation).call
    @all_thirds = @qualification[:all_thirds]
    @current_qualifying = @qualification[:qualifying_third_groups]
  end

  def update_third_place
    qualifying_groups = params[:qualifying_groups]

    QuickThirdPlaceService.new(simulation: @simulation).call(qualifying_groups)

    # Regenerate bracket with new qualifiers
    KnockoutBracketGenerator.new(simulation: @simulation).generate

    redirect_to quick_bracket_path(token: @simulation.token),
                notice: t('flash.selection_saved')
  rescue ArgumentError => e
    redirect_to quick_third_place_path(token: @simulation.token),
                alert: e.message
  end

  # Choose winner for a knockout match
  def choose_winner
    @match = Match.find_by!(match_number: params[:match_number], stage: "knockout")

    unless @match.teams_known?
      redirect_to quick_bracket_path(token: @simulation.token),
                  alert: t('flash.teams_not_determined')
      return
    end
  end

  def set_winner
    match = Match.find_by!(match_number: params[:match_number], stage: "knockout")
    winner_team_id = params[:winner_team_id].to_i

    QuickKnockoutService.new(simulation: @simulation, match: match).call(winner_team_id)

    # Update bracket progression
    KnockoutProgression.new(simulation: @simulation).update_bracket

    # Check if final was just predicted
    is_final = match.match_number == 80

    # Always redirect for final match (celebration page)
    if is_final
      redirect_to celebration_path(token: @simulation.token)
      return
    end

    respond_to do |format|
      format.turbo_stream do
        @knockout_matches = Match.knockout
                                 .includes(:home_team, :away_team)
                                 .order(:match_number)
        @matches_by_round = @knockout_matches.group_by(&:round)
        @predictions = Prediction.where(simulation: @simulation, match: @knockout_matches)
                                 .index_by(&:match_id)
      end
      format.html do
        redirect_to quick_bracket_path(token: @simulation.token),
                    notice: t('flash.winner_saved', match_number: match.match_number)
      end
    end
  rescue ArgumentError => e
    redirect_to quick_bracket_path(token: @simulation.token),
                alert: e.message
  end

  private

  def load_simulation
    @simulation = Simulation.find_by!(token: params[:token])
  end

  def ensure_quick_mode
    unless @simulation.quick_mode?
      redirect_to simulation_path(token: @simulation.token),
                  alert: t('flash.quick_mode_only')
    end
  end

  def all_groups_complete?
    Group.all.all? do |group|
      group_matches = Match.where(group: group, stage: "group_stage")
      completed = Prediction.where(simulation: @simulation, match: group_matches)
                            .where.not(home_score: nil).count
      completed == group_matches.count && group_matches.count > 0
    end
  end
end
