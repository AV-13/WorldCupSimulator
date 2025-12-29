# frozen_string_literal: true

# Service to calculate which 32 teams qualify for the knockout stage
# Based on group stage predictions for a given simulation
class KnockoutQualification
  GROUPS = %w[A B C D E F G H I J K L].freeze

  # Struct to hold third-place team data for ranking
  ThirdPlaceEntry = Struct.new(
    :group, :team, :points, :goal_diff, :goals_for, :goals_against, :played,
    keyword_init: true
  )

  def initialize(simulation:)
    @simulation = simulation
  end

  # Returns qualification data:
  # {
  #   winners: { "A" => Team, "B" => Team, ... },
  #   runners_up: { "A" => Team, "B" => Team, ... },
  #   best_thirds: [ThirdPlaceEntry, ...],  # Top 8 sorted
  #   all_thirds: [ThirdPlaceEntry, ...],   # All 12 sorted
  #   qualifying_third_groups: ["E", "F", ...],  # 8 group letters
  #   complete: true/false  # Whether all group matches have predictions
  # }
  def call
    standings = calculate_all_standings

    {
      winners: extract_position(standings, 0),
      runners_up: extract_position(standings, 1),
      best_thirds: calculate_best_thirds(standings).first(8),
      all_thirds: calculate_best_thirds(standings),
      qualifying_third_groups: calculate_best_thirds(standings).first(8).map(&:group),
      complete: all_matches_predicted?
    }
  end

  # Check if all 72 group stage matches have predictions
  def all_matches_predicted?
    group_matches = Match.where(stage: "group_stage")
    predictions = Prediction.where(simulation: @simulation, match: group_matches)
                            .where.not(home_score: nil)
                            .where.not(away_score: nil)

    predictions.count == 72
  end

  private

  def calculate_all_standings
    GROUPS.to_h do |group_name|
      group = Group.find_by(name: group_name)
      standings = GroupStandings.new(simulation: @simulation, group: group).call
      [group_name, standings]
    end
  end

  def extract_position(standings, position)
    standings.transform_values { |rows| rows[position]&.team }
  end

  def calculate_best_thirds(standings)
    thirds = standings.map do |group_name, rows|
      third = rows[2]
      next nil unless third

      ThirdPlaceEntry.new(
        group: group_name,
        team: third.team,
        points: third.points,
        goal_diff: third.goal_diff,
        goals_for: third.goals_for,
        goals_against: third.goals_against,
        played: third.played
      )
    end.compact

    # FIFA ranking criteria for third-place teams:
    # 1. Points
    # 2. Goal difference
    # 3. Goals scored
    # 4. Goals against (fewer is better) - not in standard rules, using as tiebreaker
    # 5. Fair play points (not implemented - would need card tracking)
    # 6. Drawing of lots (using group letter as deterministic tiebreaker)
    thirds.sort_by do |t|
      [-t.points, -t.goal_diff, -t.goals_for, t.goals_against, t.group]
    end
  end
end
