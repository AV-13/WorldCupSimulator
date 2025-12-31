# frozen_string_literal: true

# Helper for serializing bracket data for D3.js visualization
module BracketDataHelper
  # Serialize all bracket data for D3.js consumption
  def bracket_json_data(matches_by_round, predictions, simulation, quick_mode)
    {
      matches: serialize_matches(matches_by_round),
      predictions: serialize_predictions(predictions),
      simulationToken: simulation.token,
      quickMode: quick_mode,
      championId: determine_champion_id(matches_by_round, predictions),
      thirdPlaceWinnerId: determine_third_place_winner_id(matches_by_round, predictions)
    }
  end

  private

  def serialize_matches(matches_by_round)
    matches_by_round.flat_map do |round, matches|
      matches.map do |match|
        {
          id: match.id,
          matchNumber: match.match_number,
          round: match.round,
          homeTeam: serialize_team(match.home_team),
          awayTeam: serialize_team(match.away_team),
          homeSource: match.home_source,
          awaySource: match.away_source,
          teamsKnown: match.teams_known?
        }
      end
    end
  end

  def serialize_team(team)
    return nil unless team

    {
      id: team.id,
      name: team.name,
      shortName: team.iso_code&.upcase || team.name[0..2].upcase,
      isoCode: team.iso_code
    }
  end

  def serialize_predictions(predictions)
    result = {}
    predictions.each do |match_id, prediction|
      next unless prediction

      result[match_id] = {
        homeScore: prediction.home_score,
        awayScore: prediction.away_score
      }
    end
    result
  end

  def determine_champion_id(matches_by_round, predictions)
    final_match = matches_by_round["final"]&.first
    return nil unless final_match

    prediction = predictions[final_match.id]
    return nil unless prediction&.home_score && prediction&.away_score

    if prediction.home_score > prediction.away_score
      final_match.home_team&.id
    elsif prediction.away_score > prediction.home_score
      final_match.away_team&.id
    end
  end

  def determine_third_place_winner_id(matches_by_round, predictions)
    third_place_match = matches_by_round["third_place"]&.first
    return nil unless third_place_match

    prediction = predictions[third_place_match.id]
    return nil unless prediction&.home_score && prediction&.away_score

    if prediction.home_score > prediction.away_score
      third_place_match.home_team&.id
    elsif prediction.away_score > prediction.home_score
      third_place_match.away_team&.id
    end
  end
end
