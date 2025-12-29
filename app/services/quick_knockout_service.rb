# frozen_string_literal: true

# Service to generate a prediction from a chosen winner
# Used in "quick" mode where users just click on the team they think will win
class QuickKnockoutService
  DEFAULT_WINNER_SCORE = 2
  DEFAULT_LOSER_SCORE = 1

  def initialize(simulation:, match:)
    @simulation = simulation
    @match = match
  end

  # Generate a prediction with the chosen winner
  # @param winner_team_id [Integer] The ID of the team that wins
  def call(winner_team_id)
    validate_match!
    validate_winner!(winner_team_id)

    prediction = Prediction.find_or_initialize_by(
      simulation: @simulation,
      match: @match
    )

    if winner_team_id == @match.home_team_id
      prediction.update!(
        home_score: DEFAULT_WINNER_SCORE,
        away_score: DEFAULT_LOSER_SCORE
      )
    else
      prediction.update!(
        home_score: DEFAULT_LOSER_SCORE,
        away_score: DEFAULT_WINNER_SCORE
      )
    end

    # Update bracket progression
    KnockoutProgression.new(simulation: @simulation).update_from_match(@match.match_number)

    prediction
  end

  private

  def validate_match!
    unless @match.knockout? && @match.teams_known?
      raise ArgumentError, "Match must be a knockout match with both teams determined"
    end
  end

  def validate_winner!(winner_team_id)
    unless [@match.home_team_id, @match.away_team_id].include?(winner_team_id)
      raise ArgumentError, "Winner must be one of the teams in the match"
    end
  end
end
