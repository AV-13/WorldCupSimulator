# frozen_string_literal: true

# Service to generate realistic scores from a user-defined ranking
# Used in "quick" mode where users just drag & drop teams to rank them
class QuickRankingService
  # Score patterns that produce the desired ranking
  # Format: [home_score, away_score] for match between higher-ranked vs lower-ranked team
  SCORE_PATTERNS = {
    dominant_win: [ 3, 0 ],
    clear_win: [ 2, 0 ],
    close_win: [ 2, 1 ],
    narrow_win: [ 1, 0 ],
    draw: [ 1, 1 ]
  }.freeze

  def initialize(simulation:, group:)
    @simulation = simulation
    @group = group
  end

  # Generate predictions for all group matches based on ranking
  # @param ranked_team_ids [Array<Integer>] Team IDs in order (1st to 4th)
  def call(ranked_team_ids)
    teams = ranked_team_ids.map { |id| Team.find(id) }
    validate_teams!(teams)

    matches = Match.where(group: @group, stage: "group_stage")
    scores = generate_scores_for_ranking(teams)

    Prediction.transaction do
      matches.each do |match|
        home_idx = teams.index(match.home_team)
        away_idx = teams.index(match.away_team)

        score = scores[[ home_idx, away_idx ].sort]
        home_score, away_score = home_idx < away_idx ? score : score.reverse

        prediction = Prediction.find_or_initialize_by(
          simulation: @simulation,
          match: match
        )
        prediction.update!(home_score: home_score, away_score: away_score)
      end
    end

    true
  end

  private

  def validate_teams!(teams)
    unless teams.length == 4 && teams.all? { |t| t.group_id == @group.id }
      raise ArgumentError, "Must provide exactly 4 teams from the group"
    end
  end

  # Generate scores that will produce the desired ranking
  # Returns a hash: { [idx1, idx2] => [higher_score, lower_score] }
  def generate_scores_for_ranking(teams)
    # 6 matches in a group of 4:
    # 0v1, 0v2, 0v3, 1v2, 1v3, 2v3
    # We want: team 0 > team 1 > team 2 > team 3

    {
      # 1st vs 2nd: close win for 1st
      [ 0, 1 ] => [ 2, 1 ],
      # 1st vs 3rd: clear win for 1st
      [ 0, 2 ] => [ 2, 0 ],
      # 1st vs 4th: dominant win for 1st
      [ 0, 3 ] => [ 3, 0 ],
      # 2nd vs 3rd: close win for 2nd
      [ 1, 2 ] => [ 1, 0 ],
      # 2nd vs 4th: clear win for 2nd
      [ 1, 3 ] => [ 2, 0 ],
      # 3rd vs 4th: narrow win for 3rd
      [ 2, 3 ] => [ 1, 0 ]
    }

    # Result:
    # 1st: 3W 0D 0L, 7-1 GD, 9 pts
    # 2nd: 2W 0D 1L, 3-2 GD, 6 pts
    # 3rd: 1W 0D 2L, 1-3 GD, 3 pts
    # 4th: 0W 0D 3L, 0-5 GD, 0 pts
  end
end
