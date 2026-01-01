# frozen_string_literal: true

# Service to adjust third-place team rankings based on user selection
# Used in "quick" mode where users choose which 8 third-place teams qualify
class QuickThirdPlaceService
  def initialize(simulation:)
    @simulation = simulation
  end

  # Adjust scores to ensure the selected groups have qualifying third-place teams
  # @param qualifying_groups [Array<String>] 8 group letters (e.g., ["A", "B", "C", "D", "E", "F", "G", "H"])
  def call(qualifying_groups)
    validate_groups!(qualifying_groups)

    # Get current third-place teams
    qual = KnockoutQualification.new(simulation: @simulation).call
    current_ranking = qual[:all_thirds]

    # Check which groups need adjustment
    current_qualifying = current_ranking.first(8).map(&:group)
    groups_to_promote = qualifying_groups - current_qualifying
    groups_to_demote = current_qualifying - qualifying_groups

    return true if groups_to_promote.empty?

    # Adjust scores to change rankings
    Prediction.transaction do
      # Boost third-place teams in groups that need to qualify
      groups_to_promote.each do |group_letter|
        boost_third_place_team(group_letter)
      end

      # Reduce third-place teams in groups that should not qualify
      groups_to_demote.each do |group_letter|
        reduce_third_place_team(group_letter)
      end
    end

    true
  end

  private

  def validate_groups!(groups)
    unless groups.length == 8 && groups.uniq.length == 8
      raise ArgumentError, "Must select exactly 8 unique groups"
    end

    valid_groups = %w[A B C D E F G H I J K L]
    unless groups.all? { |g| valid_groups.include?(g.to_s.upcase) }
      raise ArgumentError, "Invalid group letter"
    end
  end

  # Add bonus points to third-place team by adjusting their match scores
  def boost_third_place_team(group_letter)
    group = Group.find_by!(name: group_letter)
    standings = GroupStandings.new(simulation: @simulation, group: group).call
    third_place = standings[2]
    fourth_place = standings[3]

    # Find match between 3rd and 4th place teams
    match = Match.where(group: group, stage: "group_stage")
                 .find do |m|
                   [ m.home_team_id, m.away_team_id ].sort ==
                     [ third_place.team.id, fourth_place.team.id ].sort
                 end

    return unless match

    # Make third place win more convincingly
    prediction = Prediction.find_by(simulation: @simulation, match: match)
    return unless prediction

    if match.home_team_id == third_place.team.id
      prediction.update!(home_score: 3, away_score: 0)
    else
      prediction.update!(home_score: 0, away_score: 3)
    end
  end

  # Reduce points of third-place team
  def reduce_third_place_team(group_letter)
    group = Group.find_by!(name: group_letter)
    standings = GroupStandings.new(simulation: @simulation, group: group).call
    third_place = standings[2]
    fourth_place = standings[3]

    match = Match.where(group: group, stage: "group_stage")
                 .find do |m|
                   [ m.home_team_id, m.away_team_id ].sort ==
                     [ third_place.team.id, fourth_place.team.id ].sort
                 end

    return unless match

    prediction = Prediction.find_by(simulation: @simulation, match: match)
    return unless prediction

    # Make it a draw (removes win bonus)
    prediction.update!(home_score: 0, away_score: 0)
  end
end
