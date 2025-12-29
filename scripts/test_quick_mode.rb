#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for quick mode implementation

puts "=== Test Quick Mode Implementation ==="
puts ""

# Create a quick mode simulation
sim = Simulation.create!(pseudo: "Test Quick", mode: "quick")
puts "Simulation created: #{sim.token} (mode: #{sim.mode})"
puts "Quick mode?: #{sim.quick_mode?}"

# Test ranking a group
puts ""
puts "=== Test QuickRankingService ==="
group_a = Group.find_by!(name: "A")
teams = group_a.teams.to_a
puts "Group A teams: #{teams.map(&:name).join(', ')}"

# Rank them in reverse order (4th team becomes 1st)
ranked_ids = teams.reverse.map(&:id)
puts "Ranking: #{teams.reverse.map(&:name).join(' > ')}"

QuickRankingService.new(simulation: sim, group: group_a).call(ranked_ids)

# Check the standings
standings = GroupStandings.new(simulation: sim, group: group_a).call
puts ""
puts "Resulting standings:"
standings.each_with_index do |row, i|
  puts "  #{i + 1}. #{row.team.name} - #{row.points}pts, #{row.goal_diff}gd"
end

# Rank all other groups with default order (1st stays 1st)
puts ""
puts "=== Ranking all other groups ==="
%w[B C D E F G H I J K L].each do |group_name|
  group = Group.find_by!(name: group_name)
  team_ids = group.teams.order(:id).pluck(:id)
  QuickRankingService.new(simulation: sim, group: group).call(team_ids)
  puts "Group #{group_name} ranked"
end

# Check qualification
puts ""
puts "=== Test KnockoutQualification ==="
qual = KnockoutQualification.new(simulation: sim).call
puts "Complete: #{qual[:complete]}"
puts "Qualifying 3rd place groups: #{qual[:qualifying_third_groups].join(', ')}"

# Generate bracket
puts ""
puts "=== Generate Bracket ==="
bracket = KnockoutBracketGenerator.new(simulation: sim).generate
puts "Knockout matches: #{bracket.count}"

# Test choosing a winner
puts ""
puts "=== Test QuickKnockoutService ==="
match_49 = Match.find_by!(match_number: 49)
puts "Match 49: #{match_49.home_team.name} vs #{match_49.away_team.name}"

QuickKnockoutService.new(simulation: sim, match: match_49).call(match_49.away_team_id)
puts "Winner set: #{match_49.away_team.name}"

# Check prediction was created
prediction = Prediction.find_by(simulation: sim, match: match_49)
puts "Prediction: #{prediction.home_score} - #{prediction.away_score}"

puts ""
puts "=== Test Complete ==="
puts "Quick mode simulation URL: /s/#{sim.token}"
puts "View bracket at: /s/#{sim.token}/quick/bracket"
