# frozen_string_literal: true

# Service to update knockout bracket teams based on match predictions
# Resolves "W49" (winner of match 49) and "L77" (loser of match 77) references
class KnockoutProgression
  ROUND_ORDER = %w[round_of_32 round_of_16 quarter_final semi_final third_place final].freeze

  def initialize(simulation:)
    @simulation = simulation
    @predictions_cache = {}
  end

  # Update all knockout matches with resolved teams
  def update_bracket
    knockout_matches.order(:match_number).each do |match|
      update_match_teams(match)
    end
  end

  # Update a specific match and all dependent matches
  def update_from_match(match_number)
    match = Match.find_by(match_number: match_number)
    return unless match

    # Find all matches that depend on this one
    dependent_matches = knockout_matches.where(
      "home_source LIKE ? OR away_source LIKE ?",
      "%#{match_number}%", "%#{match_number}%"
    )

    dependent_matches.each do |dep_match|
      update_match_teams(dep_match)
    end
  end

  # Get the winner of a specific match based on prediction
  def winner_of(match_number)
    match = Match.find_by(match_number: match_number)
    return nil unless match

    prediction = prediction_for(match)
    return nil unless prediction&.home_score && prediction&.away_score

    determine_winner(match, prediction)
  end

  # Get the loser of a specific match based on prediction
  def loser_of(match_number)
    match = Match.find_by(match_number: match_number)
    return nil unless match

    prediction = prediction_for(match)
    return nil unless prediction&.home_score && prediction&.away_score

    determine_loser(match, prediction)
  end

  private

  def knockout_matches
    Match.where(stage: "knockout")
  end

  def update_match_teams(match)
    # Round of 32 teams are set by KnockoutBracketGenerator
    return if match.round == "round_of_32"

    home_team = resolve_source(match.home_source)
    away_team = resolve_source(match.away_source)

    # Only update if teams have changed
    if home_team != match.home_team || away_team != match.away_team
      match.update!(home_team: home_team, away_team: away_team)
    end
  end

  def resolve_source(source)
    case source
    when /^W(\d+)$/
      # Winner of match X
      winner_of($1.to_i)
    when /^L(\d+)$/
      # Loser of match X (for third-place match)
      loser_of($1.to_i)
    else
      nil
    end
  end

  def prediction_for(match)
    @predictions_cache[match.id] ||= Prediction.find_by(
      simulation: @simulation,
      match: match
    )
  end

  def determine_winner(match, prediction)
    home_score = prediction.home_score
    away_score = prediction.away_score

    if home_score > away_score
      match.home_team
    elsif away_score > home_score
      match.away_team
    else
      # Tie in knockout - need to handle extra time/penalties
      # For now, we'll need additional data to determine winner
      # Default: home team wins (could be improved with penalty prediction)
      handle_knockout_tie(match, prediction, :winner)
    end
  end

  def determine_loser(match, prediction)
    home_score = prediction.home_score
    away_score = prediction.away_score

    if home_score > away_score
      match.away_team
    elsif away_score > home_score
      match.home_team
    else
      handle_knockout_tie(match, prediction, :loser)
    end
  end

  # Handle tied knockout matches
  # In a real implementation, this would check for penalty shootout prediction
  # For now, we use a deterministic rule: home team wins ties
  def handle_knockout_tie(match, _prediction, result_type)
    # TODO: Implement penalty shootout prediction
    # For now, home team wins all ties
    case result_type
    when :winner
      match.home_team
    when :loser
      match.away_team
    end
  end
end
