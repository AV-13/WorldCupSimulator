#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to convert FIFA 495 combinations from PDF-extracted CSV to Ruby Hash
# Source: FIFA World Cup 2026 Regulations, Annex C (page 80-95)

require 'fileutils'

INPUT_FILE = File.expand_path('../../combination.csv', __FILE__)
OUTPUT_FILE = File.expand_path('../../app/services/third_place_combinations_data.rb', __FILE__)

# Column headers in order (which group winner faces which 3rd place team)
# Note: Groups C, F, H, J winners play against runners-up, not 3rd place teams
COLUMNS = %w[1A 1B 1D 1E 1G 1I 1K 1L]

def parse_combinations
  combinations = {}
  errors = []

  lines = File.readlines(INPUT_FILE, chomp: true)

  lines.each_with_index do |line, idx|
    # Skip header line
    next if line.start_with?('Option')

    # Skip PDF artifacts (page numbers, "Annexes", etc.)
    next if line =~ /^Annexes/i
    next if line =~ /^\d+\s+\d+$/  # "82 83", "84 85", etc.
    next if line.strip.empty?

    # Parse the line: "1 3E 3J 3I 3F 3H 3G 3L 3K"
    parts = line.split(/\s+/)

    # First part is option number, rest are the 8 assignments
    option_num = parts[0].to_i
    assignments = parts[1..8]

    if assignments.length != 8
      errors << "Line #{idx + 1}: Expected 8 assignments, got #{assignments.length}: #{line}"
      next
    end

    # Extract group letters from "3X" format
    groups = assignments.map do |assignment|
      if assignment =~ /^3([A-L])$/
        $1
      else
        errors << "Line #{idx + 1}: Invalid assignment format '#{assignment}'"
        nil
      end
    end

    next if groups.any?(&:nil?)

    # The key is the sorted combination of qualifying groups
    key = groups.sort.join

    # Build the assignment hash
    assignment_hash = {}
    COLUMNS.each_with_index do |col, i|
      winner_group = col[1] # "1A" -> "A"
      assignment_hash[winner_group.to_sym] = groups[i]
    end

    # Check for duplicate keys (shouldn't happen with valid data)
    if combinations.key?(key)
      # Same key can appear if multiple options lead to same qualifying groups
      # This is actually expected - we just verify they have the same assignment
      if combinations[key] != assignment_hash
        errors << "Line #{idx + 1}: Duplicate key #{key} with different assignments!"
      end
    else
      combinations[key] = assignment_hash
    end
  end

  [combinations, errors]
end

def generate_ruby_file(combinations)
  output = <<~RUBY
    # frozen_string_literal: true

    # FIFA World Cup 2026 - Third Place Combinations Table
    # Auto-generated from FIFA regulations Annex C (pages 80-95)
    # Source: https://digitalhub.fifa.com/m/636f5c9c6f29771f/original/FWC2026_regulations_EN.pdf
    #
    # This module contains the official 495 combinations that determine
    # which third-place team plays against which group winner in the Round of 32.
    #
    # Key: 8-letter string of qualifying third-place groups (sorted alphabetically)
    # Value: Hash mapping group winner to the third-place team they face
    #        e.g., { A: "E", B: "J", ... } means 1A plays 3E, 1B plays 3J, etc.
    #
    # Note: Only groups A, B, D, E, G, I, K, L winners play against 3rd-place teams.
    #       Groups C, F, H, J winners play against runners-up.

    module ThirdPlaceCombinationsData
      # The 8 group winners who face third-place teams
      THIRD_PLACE_OPPONENT_GROUPS = %w[A B D E G I K L].freeze

      # Groups whose winners face runners-up (not third-place teams)
      RUNNER_UP_OPPONENT_GROUPS = %w[C F H J].freeze

      COMBINATIONS = {
  RUBY

  combinations.sort.each do |key, assignment|
    formatted = assignment.map { |k, v| "#{k}: \"#{v}\"" }.join(", ")
    output += "    \"#{key}\" => { #{formatted} },\n"
  end

  output += <<~RUBY
      }.freeze

      def self.lookup(qualifying_groups)
        key = qualifying_groups.map(&:to_s).map(&:upcase).sort.join
        COMBINATIONS[key]
      end

      def self.valid_key?(key)
        COMBINATIONS.key?(key)
      end

      def self.all_keys
        COMBINATIONS.keys
      end

      def self.count
        COMBINATIONS.size
      end
    end
  RUBY

  output
end

def main
  puts "Reading #{INPUT_FILE}..."
  combinations, errors = parse_combinations

  if errors.any?
    puts "\nErrors found:"
    errors.each { |e| puts "  - #{e}" }
  end

  puts "\nParsed #{combinations.size} unique combinations"

  if combinations.size != 495
    puts "WARNING: Expected 495 combinations, got #{combinations.size}"
  end

  # Verify all combinations have valid keys (8 unique letters)
  invalid_keys = combinations.keys.reject { |k| k.length == 8 && k.chars.uniq.length == 8 }
  if invalid_keys.any?
    puts "WARNING: Invalid keys found: #{invalid_keys}"
  end

  puts "\nGenerating #{OUTPUT_FILE}..."
  FileUtils.mkdir_p(File.dirname(OUTPUT_FILE))
  File.write(OUTPUT_FILE, generate_ruby_file(combinations))

  puts "Done! Generated #{combinations.size} combinations."

  # Print sample
  puts "\nSample entries:"
  combinations.first(3).each do |key, assignment|
    puts "  #{key} => #{assignment}"
  end
end

main if __FILE__ == $PROGRAM_NAME
