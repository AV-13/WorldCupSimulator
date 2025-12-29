# frozen_string_literal: true

# Service to lookup third-place team assignments for the Round of 32
# Uses the official FIFA 495 combinations table from Annex C
class ThirdPlaceCombinations
  # Group winners who face third-place teams in Round of 32
  # (Groups C, F, H, J winners face runners-up instead)
  THIRD_PLACE_OPPONENT_WINNERS = %w[A B D E G I K L].freeze

  # Validates that the assignment respects FIFA rules:
  # - Each 3rd-place team is assigned exactly once
  # - No 3rd-place team faces their own group winner
  def self.lookup(qualifying_groups)
    groups = normalize_groups(qualifying_groups)
    ThirdPlaceCombinationsData.lookup(groups)
  end

  def self.valid?(qualifying_groups)
    groups = normalize_groups(qualifying_groups)
    return false unless groups.length == 8
    return false unless groups == groups.uniq

    ThirdPlaceCombinationsData.valid_key?(groups.sort.join)
  end

  # Returns which group winner a specific third-place team will face
  # given the qualifying groups
  def self.opponent_for_third(qualifying_groups, third_place_group)
    assignment = lookup(qualifying_groups)
    return nil unless assignment

    # Find which winner faces this third-place team
    assignment.find { |_winner, third| third == third_place_group.to_s.upcase }&.first
  end

  # Returns which third-place team a specific group winner will face
  def self.third_place_for_winner(qualifying_groups, winner_group)
    assignment = lookup(qualifying_groups)
    return nil unless assignment

    assignment[winner_group.to_s.upcase.to_sym]
  end

  private

  def self.normalize_groups(groups)
    groups.map { |g| g.to_s.upcase }.sort
  end
end
