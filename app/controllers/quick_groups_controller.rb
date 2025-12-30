# frozen_string_literal: true

# Controller for quick mode group ranking
class QuickGroupsController < ApplicationController
  before_action :load_simulation
  before_action :ensure_quick_mode
  before_action :load_group, only: [:show, :update]

  def show
    @teams = @group.teams.to_a

    # Get current ranking if predictions exist
    if predictions_exist?
      standings = GroupStandings.new(simulation: @simulation, group: @group).call
      @teams = standings.map(&:team)
    end
  end

  def update
    ranked_team_ids = params[:team_ids].map(&:to_i)

    QuickRankingService.new(simulation: @simulation, group: @group).call(ranked_team_ids)

    redirect_to simulation_path(token: @simulation.token),
                notice: t('flash.ranking_saved', group: @group.name)
  rescue ArgumentError => e
    redirect_to quick_group_path(token: @simulation.token, name: @group.name),
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

  def load_group
    @group = Group.find_by!(name: params[:name])
  end

  def predictions_exist?
    matches = Match.where(group: @group, stage: "group_stage")
    Prediction.where(simulation: @simulation, match: matches)
              .where.not(home_score: nil)
              .exists?
  end
end
