# frozen_string_literal: true

# Service to generate the knockout stage bracket (32 matches)
# Uses official FIFA bracket structure and 495 combinations table
class KnockoutBracketGenerator
  # Round of 32 bracket structure (16 matches)
  # home_source/away_source format:
  #   "1A" = Winner of Group A
  #   "2A" = Runner-up of Group A
  #   :third_A = Third-place team facing group A winner (resolved via 495 table)
  ROUND_OF_32 = [
    # Match 49-56 (Left side of bracket)
    { number: 49, round: "round_of_32", home: "1E", away: :third_E },
    { number: 50, round: "round_of_32", home: "1I", away: :third_I },
    { number: 51, round: "round_of_32", home: "2A", away: "2B" },
    { number: 52, round: "round_of_32", home: "1F", away: "2C" },
    { number: 53, round: "round_of_32", home: "2K", away: "2L" },
    { number: 54, round: "round_of_32", home: "1H", away: "2J" },
    { number: 55, round: "round_of_32", home: "1D", away: :third_D },
    { number: 56, round: "round_of_32", home: "1G", away: :third_G },
    # Match 57-64 (Right side of bracket)
    { number: 57, round: "round_of_32", home: "1C", away: "2F" },
    { number: 58, round: "round_of_32", home: "2E", away: "2I" },
    { number: 59, round: "round_of_32", home: "1A", away: :third_A },
    { number: 60, round: "round_of_32", home: "1L", away: :third_L },
    { number: 61, round: "round_of_32", home: "1J", away: "2H" },
    { number: 62, round: "round_of_32", home: "2D", away: "2G" },
    { number: 63, round: "round_of_32", home: "1B", away: :third_B },
    { number: 64, round: "round_of_32", home: "1K", away: :third_K }
  ].freeze

  ROUND_OF_16 = [
    { number: 65, round: "round_of_16", home: "W49", away: "W50" },
    { number: 66, round: "round_of_16", home: "W51", away: "W52" },
    { number: 67, round: "round_of_16", home: "W53", away: "W54" },
    { number: 68, round: "round_of_16", home: "W55", away: "W56" },
    { number: 69, round: "round_of_16", home: "W57", away: "W58" },
    { number: 70, round: "round_of_16", home: "W59", away: "W60" },
    { number: 71, round: "round_of_16", home: "W61", away: "W62" },
    { number: 72, round: "round_of_16", home: "W63", away: "W64" }
  ].freeze

  QUARTER_FINALS = [
    { number: 73, round: "quarter_final", home: "W65", away: "W66" },
    { number: 74, round: "quarter_final", home: "W67", away: "W68" },
    { number: 75, round: "quarter_final", home: "W69", away: "W70" },
    { number: 76, round: "quarter_final", home: "W71", away: "W72" }
  ].freeze

  SEMI_FINALS = [
    { number: 77, round: "semi_final", home: "W73", away: "W74" },
    { number: 78, round: "semi_final", home: "W75", away: "W76" }
  ].freeze

  THIRD_PLACE_MATCH = [
    { number: 79, round: "third_place", home: "L77", away: "L78" }
  ].freeze

  FINAL = [
    { number: 80, round: "final", home: "W77", away: "W78" }
  ].freeze

  ALL_KNOCKOUT_MATCHES = (
    ROUND_OF_32 + ROUND_OF_16 + QUARTER_FINALS +
    SEMI_FINALS + THIRD_PLACE_MATCH + FINAL
  ).freeze

  def initialize(simulation:)
    @simulation = simulation
  end

  # Generate or update all knockout matches based on current group stage predictions
  def generate
    qualification = KnockoutQualification.new(simulation: @simulation).call
    third_assignments = ThirdPlaceCombinations.lookup(qualification[:qualifying_third_groups])

    Match.transaction do
      ALL_KNOCKOUT_MATCHES.each do |match_def|
        create_or_update_match(match_def, qualification, third_assignments)
      end
    end

    Match.where(stage: "knockout").order(:match_number)
  end

  # Only generate Round of 32 matches (useful for initial setup)
  def generate_round_of_32
    qualification = KnockoutQualification.new(simulation: @simulation).call
    third_assignments = ThirdPlaceCombinations.lookup(qualification[:qualifying_third_groups])

    Match.transaction do
      ROUND_OF_32.each do |match_def|
        create_or_update_match(match_def, qualification, third_assignments)
      end
    end

    Match.where(stage: "knockout", round: "round_of_32").order(:match_number)
  end

  private

  def create_or_update_match(match_def, qualification, third_assignments)
    match = Match.find_or_initialize_by(match_number: match_def[:number])

    home_source = resolve_source_string(match_def[:home], third_assignments)
    away_source = resolve_source_string(match_def[:away], third_assignments)

    # Only resolve actual teams for Round of 32
    # Later rounds will be resolved by KnockoutProgression service
    home_team = nil
    away_team = nil

    if match_def[:round] == "round_of_32"
      home_team = resolve_team(match_def[:home], qualification, third_assignments)
      away_team = resolve_team(match_def[:away], qualification, third_assignments)
    end

    match.assign_attributes(
      stage: "knockout",
      round: match_def[:round],
      home_source: home_source,
      away_source: away_source,
      home_team: home_team,
      away_team: away_team,
      group: nil
    )

    match.save!
    match
  end

  def resolve_source_string(source, third_assignments)
    case source
    when Symbol
      # :third_A means "third place team facing group A winner"
      winner_group = source.to_s.sub("third_", "")
      third_group = third_assignments&.dig(winner_group.to_sym)
      "3#{third_group}"
    else
      source.to_s
    end
  end

  def resolve_team(source, qualification, third_assignments)
    case source
    when /^1([A-L])$/
      # Group winner
      qualification[:winners][$1]
    when /^2([A-L])$/
      # Group runner-up
      qualification[:runners_up][$1]
    when Symbol
      # Third-place team
      winner_group = source.to_s.sub("third_", "")
      third_group = third_assignments&.dig(winner_group.to_sym)
      return nil unless third_group

      third_entry = qualification[:best_thirds].find { |t| t.group == third_group }
      third_entry&.team
    else
      nil # W/L references resolved later by KnockoutProgression
    end
  end
end
