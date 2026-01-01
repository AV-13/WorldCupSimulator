#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the complete mode (manual score entry)

puts "=== Test Complete Mode ==="
puts ""

# Create a complete mode simulation
sim = Simulation.create!(pseudo: "Test Complete", mode: "complete")
puts "Simulation created: #{sim.token} (mode: #{sim.mode})"
puts "Complete mode?: #{sim.complete_mode?}"

# Enter predictions for one group manually
puts ""
puts "=== Entering predictions for Group A ==="
group_a = Group.find_by!(name: "A")
matches = Match.where(group: group_a, stage: "group_stage")

# Simple scores: 1-0, 2-1, etc.
scores = [ [ 2, 1 ], [ 1, 0 ], [ 3, 0 ], [ 2, 2 ], [ 1, 1 ], [ 2, 0 ] ]

matches.each_with_index do |match, i|
  Prediction.create!(
    simulation: sim,
    match: match,
    home_score: scores[i][0],
    away_score: scores[i][1]
  )
  puts "  Match #{match.match_number}: #{match.home_team.name} #{scores[i][0]}-#{scores[i][1]} #{match.away_team.name}"
end

# Check standings
puts ""
puts "=== Group A Standings ==="
standings = GroupStandings.new(simulation: sim, group: group_a).call
standings.each_with_index do |row, i|
  puts "  #{i + 1}. #{row.team.name} - #{row.points}pts, #{row.goal_diff}gd"
end

# Check incomplete qualification
puts ""
puts "=== Qualification Status ==="
qual = KnockoutQualification.new(simulation: sim).call
puts "Complete: #{qual[:complete]}"
puts "Groups completed: #{Match.where(stage: 'group_stage').group(:group_id).having('count(*) = count(distinct predictions.id) FILTER (WHERE predictions.home_score IS NOT NULL)').count.keys.count rescue 'N/A'}"

puts ""
puts "=== Complete Mode Test Done ==="
puts "URL: /s/#{sim.token}"
