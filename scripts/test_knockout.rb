#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for knockout stage implementation

puts "=== Test Knockout Stage Implementation ==="
puts ""

# Create a test simulation
sim = Simulation.create!(pseudo: "Test Knockout")
puts "Simulation created: #{sim.token}"

# Create predictions for all group stage matches (random scores)
Match.group_stage.each do |match|
  Prediction.create!(
    simulation: sim,
    match: match,
    home_score: rand(0..4),
    away_score: rand(0..4)
  )
end
puts "Predictions created: #{Prediction.where(simulation: sim).count}"

# Test qualification
qual = KnockoutQualification.new(simulation: sim).call
puts ""
puts "=== Qualification ==="
puts "Complete: #{qual[:complete]}"
puts "Winners:"
qual[:winners].each { |g, t| puts "  Group #{g}: #{t&.name}" }
puts ""
puts "Best 8 thirds from groups: #{qual[:qualifying_third_groups].join(', ')}"
puts ""
puts "Third place ranking:"
qual[:all_thirds].each_with_index do |t, i|
  status = i < 8 ? "QUALIFIED" : "eliminated"
  puts "  #{i + 1}. Group #{t.group}: #{t.team&.name} (#{t.points}pts, #{t.goal_diff}gd) - #{status}"
end

# Generate bracket
puts ""
puts "=== Generating Bracket ==="
bracket = KnockoutBracketGenerator.new(simulation: sim).generate
puts "Knockout matches generated: #{bracket.count}"

# Show Round of 32
puts ""
puts "=== Round of 32 ==="
Match.round_of_32.order(:match_number).each do |m|
  home = m.home_team&.name || m.home_source
  away = m.away_team&.name || m.away_source
  puts "Match #{m.match_number}: #{home} vs #{away}"
end

# Show later rounds (teams TBD)
puts ""
puts "=== Round of 16 ==="
Match.round_of_16.order(:match_number).each do |m|
  puts "Match #{m.match_number}: #{m.home_source} vs #{m.away_source}"
end

puts ""
puts "=== Quarter Finals ==="
Match.quarter_finals.order(:match_number).each do |m|
  puts "Match #{m.match_number}: #{m.home_source} vs #{m.away_source}"
end

puts ""
puts "=== Semi Finals ==="
Match.semi_finals.order(:match_number).each do |m|
  puts "Match #{m.match_number}: #{m.home_source} vs #{m.away_source}"
end

puts ""
puts "=== Final ==="
Match.final_match.each do |m|
  puts "Match #{m.match_number}: #{m.home_source} vs #{m.away_source}"
end

puts ""
puts "=== Test Complete ==="
puts "View the bracket at: /s/#{sim.token}/bracket"
