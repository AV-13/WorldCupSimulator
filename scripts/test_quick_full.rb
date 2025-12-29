#!/usr/bin/env ruby
# frozen_string_literal: true

# Full test of quick mode

# Create fresh simulation
sim = Simulation.create!(pseudo: "Test Quick Full", mode: "quick")
puts "New simulation: #{sim.token}"

# Rank all groups
Group.order(:name).each do |group|
  team_ids = group.teams.order(:id).pluck(:id)
  QuickRankingService.new(simulation: sim, group: group).call(team_ids)

  preds = Prediction.joins(:match)
                    .where(simulation: sim)
                    .where(matches: { group: group, stage: "group_stage" })
                    .count
  puts "Group #{group.name}: #{preds}/6"
end

# Total
total = Prediction.joins(:match)
                  .where(simulation: sim)
                  .where(matches: { stage: "group_stage" })
                  .where.not(home_score: nil)
                  .count
puts ""
puts "Total group predictions: #{total}/72"

# Check qualification
qual = KnockoutQualification.new(simulation: sim).call
puts "Complete: #{qual[:complete]}"
puts "Best 3rds: #{qual[:qualifying_third_groups].join(', ')}"

# Generate bracket
puts ""
puts "Generating bracket..."
KnockoutBracketGenerator.new(simulation: sim).generate
puts "Knockout matches: #{Match.knockout.count}"

# Show Round of 32
puts ""
puts "=== Round of 32 ==="
Match.round_of_32.order(:match_number).limit(4).each do |m|
  puts "Match #{m.match_number}: #{m.home_team&.name} vs #{m.away_team&.name}"
end
puts "..."

puts ""
puts "=== Quick mode test complete ==="
puts "URL: /s/#{sim.token}/quick/bracket"
