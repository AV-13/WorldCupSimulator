#!/usr/bin/env ruby
# frozen_string_literal: true

# Full test of complete mode (manual score entry)

puts "=== Test Complete Mode (Full) ==="
puts ""

# Create a complete mode simulation
sim = Simulation.create!(pseudo: "Test Complete Full", mode: "complete")
puts "Simulation: #{sim.token} (mode: #{sim.mode})"

# Enter scores for all 72 group matches
puts ""
puts "=== Entering scores for all groups ==="

Group.order(:name).each do |group|
  matches = Match.where(group: group, stage: "group_stage")
  teams = group.teams.to_a

  # Generate realistic scores where team order = final ranking
  matches.each do |match|
    home_idx = teams.index(match.home_team)
    away_idx = teams.index(match.away_team)

    # Higher ranked team wins (or draws if close)
    if home_idx < away_idx
      home_score = 2
      away_score = home_idx == away_idx - 1 ? 1 : 0
    else
      away_score = 2
      home_score = away_idx == home_idx - 1 ? 1 : 0
    end

    Prediction.create!(
      simulation: sim,
      match: match,
      home_score: home_score,
      away_score: away_score
    )
  end

  preds = Prediction.where(simulation: sim, match: matches).where.not(home_score: nil).count
  puts "Group #{group.name}: #{preds}/6 predictions"
end

# Check total predictions
total = Prediction.where(simulation: sim).joins(:match).where(matches: { stage: "group_stage" }).count
puts ""
puts "Total group predictions: #{total}/72"

# Check qualification
puts ""
puts "=== Qualification ==="
qual = KnockoutQualification.new(simulation: sim).call
puts "Complete: #{qual[:complete]}"
puts "Best 3rds from: #{qual[:qualifying_third_groups].join(', ')}"

# Generate bracket
puts ""
puts "=== Bracket Generation ==="
if qual[:complete]
  KnockoutBracketGenerator.new(simulation: sim).generate
  puts "Knockout matches: #{Match.knockout.count}"

  # Show Round of 32
  puts ""
  puts "=== Round of 32 (first 4 matches) ==="
  Match.round_of_32.order(:match_number).limit(4).each do |m|
    puts "Match #{m.match_number}: #{m.home_team&.name} vs #{m.away_team&.name}"
  end
  puts "..."

  # Test entering a knockout prediction
  puts ""
  puts "=== Test Knockout Prediction ==="
  match_49 = Match.find_by!(match_number: 49)
  puts "Match 49: #{match_49.home_team.name} vs #{match_49.away_team.name}"

  pred = Prediction.find_or_initialize_by(simulation: sim, match: match_49)
  pred.update!(home_score: 2, away_score: 1)
  puts "Prediction: 2-1 (#{match_49.home_team.name} wins)"

  # Update bracket
  KnockoutProgression.new(simulation: sim).update_from_match(49)

  # Check if R16 match got updated
  match_65 = Match.find_by!(match_number: 65)
  puts ""
  puts "Match 65 (R16): #{match_65.home_team&.name || match_65.home_source} vs #{match_65.away_team&.name || match_65.away_source}"
else
  puts "Group stage not complete - cannot generate bracket"
end

puts ""
puts "=== Complete Mode Test Done ==="
puts "URL: /s/#{sim.token}"
puts "Bracket URL: /s/#{sim.token}/bracket"
