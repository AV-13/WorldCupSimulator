# frozen_string_literal: true

class BracketsController < ApplicationController
  before_action :load_simulation

  def show
    # Calculate qualification status
    @qualification = KnockoutQualification.new(simulation: @simulation).call

    # Generate/update knockout bracket if group stage is complete enough
    if @qualification[:qualifying_third_groups].length == 8
      KnockoutBracketGenerator.new(simulation: @simulation).generate
      KnockoutProgression.new(simulation: @simulation).update_bracket
    end

    # Load knockout matches grouped by round
    @knockout_matches = Match.knockout
                             .includes(:home_team, :away_team)
                             .order(:match_number)

    @matches_by_round = @knockout_matches.group_by(&:round)

    # Load predictions for this simulation
    @predictions = Prediction.where(simulation: @simulation, match: @knockout_matches)
                             .index_by(&:match_id)
  end

  private

  def load_simulation
    @simulation = Simulation.find_by!(token: params[:token])
  end
end
