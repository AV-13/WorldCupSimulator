# frozen_string_literal: true

class CelebrationsController < ApplicationController
  before_action :load_simulation

  def show
    @final_match = Match.find_by!(match_number: 80, stage: "knockout")
    @third_place_match = Match.find_by!(match_number: 79, stage: "knockout")

    @final_prediction = Prediction.find_by(simulation: @simulation, match: @final_match)
    @third_place_prediction = Prediction.find_by(simulation: @simulation, match: @third_place_match)

    # Redirect back if final not yet predicted
    unless @final_prediction&.home_score && @final_prediction&.away_score
      redirect_to bracket_path(token: @simulation.token) and return
    end

    # Determine podium
    @champion = determine_winner(@final_match, @final_prediction)
    @runner_up = determine_loser(@final_match, @final_prediction)
    @third_place = if @third_place_prediction&.home_score && @third_place_prediction&.away_score
                     determine_winner(@third_place_match, @third_place_prediction)
                   end

    # Calculate stats for complete mode
    @stats = calculate_stats if @simulation.complete_mode?
  end

  private

  def load_simulation
    @simulation = Simulation.find_by!(token: params[:token])
  end

  def determine_winner(match, prediction)
    return nil unless prediction&.home_score && prediction&.away_score
    prediction.home_score > prediction.away_score ? match.home_team : match.away_team
  end

  def determine_loser(match, prediction)
    return nil unless prediction&.home_score && prediction&.away_score
    prediction.home_score > prediction.away_score ? match.away_team : match.home_team
  end

  def calculate_stats
    predictions = Prediction.where(simulation: @simulation).where.not(home_score: nil)

    total_goals = predictions.sum(:home_score) + predictions.sum(:away_score)
    total_matches = predictions.count

    # Group stage stats
    group_matches = Match.where(stage: "group_stage").pluck(:id)
    group_predictions = predictions.where(match_id: group_matches)

    draws = group_predictions.where("home_score = away_score").count
    home_wins = group_predictions.where("home_score > away_score").count
    away_wins = group_predictions.where("home_score < away_score").count

    # Biggest victory
    biggest_margin = predictions.maximum("ABS(home_score - away_score)") || 0

    {
      total_matches: total_matches,
      total_goals: total_goals,
      avg_goals: total_matches > 0 ? (total_goals.to_f / total_matches).round(2) : 0,
      draws: draws,
      home_wins: home_wins,
      away_wins: away_wins,
      biggest_margin: biggest_margin
    }
  end
end
