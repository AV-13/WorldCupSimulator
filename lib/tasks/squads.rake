namespace :squads do
  # Mapping for ISO codes that differ between JSON and database
  ISO_CODE_MAPPING = {
    "en" => "gb-eng",  # England
    "wl" => "gb-wls",  # Wales
    "sc" => "gb-sct"   # Scotland (if needed)
  }.freeze

  desc "Import squads from JSON file"
  task import: :environment do
    json_path = ENV.fetch("SQUADS_JSON", Rails.root.join("world_cup_squads_complete.json"))

    unless File.exist?(json_path)
      puts "❌ File not found: #{json_path}"
      exit 1
    end

    # Read and parse JSON (handle NaN values which are not valid JSON)
    raw_content = File.read(json_path)
    sanitized_content = raw_content.gsub(/:\s*NaN\s*(,|\})/) { ": null#{$1}" }
    data = JSON.parse(sanitized_content)

    total_players = 0
    total_coaches = 0
    missing_teams = []

    ActiveRecord::Base.transaction do
      data["teams"].each do |team_data|
        iso_code = ISO_CODE_MAPPING[team_data["iso_code"]] || team_data["iso_code"]
        team = Team.find_by(iso_code: iso_code)

        unless team
          missing_teams << team_data["iso_code"]
          next
        end

        # Clear existing players and coach for this team
        team.players.destroy_all
        team.coach&.destroy

        # Import Coach
        if team_data["coach"]
          team.create_coach!(
            first_name: team_data["coach"]["first_name"],
            last_name: team_data["coach"]["last_name"]
          )
          total_coaches += 1
        end

        # Import Players
        team_data["players"].each do |p|
          team.players.create!(
            fm_uid: p["fm_uid"],
            fotmob_id: p["fotmob_id"],
            first_name: p["first_name"],
            last_name: p["last_name"],
            position: p["position"],
            jersey_number: p["jersey_number"],
            club: p["club"],
            birth_date: p["birth_date"],
            is_starter: p["is_starter"] || false,
            grid_row: p["grid_row"],
            grid_col: p["grid_col"]
          )
          total_players += 1
        end

        puts "✓ #{team.name}: #{team_data['players'].size} players"
      end
    end

    puts ""
    puts "=" * 50
    puts "Import completed!"
    puts "  Teams: #{data['teams'].size - missing_teams.size}"
    puts "  Players: #{total_players}"
    puts "  Coaches: #{total_coaches}"

    if missing_teams.any?
      puts ""
      puts "⚠️  Missing teams (iso_code not found):"
      missing_teams.each { |code| puts "  - #{code}" }
    end
  end

  desc "Clear all players and coaches"
  task clear: :environment do
    Player.destroy_all
    Coach.destroy_all
    puts "✓ All players and coaches cleared"
  end

  desc "Show squad stats"
  task stats: :environment do
    puts "Squad Statistics"
    puts "=" * 50
    puts "Total players: #{Player.count}"
    puts "Total coaches: #{Coach.count}"
    puts "Teams with players: #{Team.joins(:players).distinct.count}"
    puts "Teams with coaches: #{Team.joins(:coach).count}"
    puts ""
    puts "Players by position:"
    Player.group(:position).count.sort_by { |_, v| -v }.each do |position, count|
      puts "  #{position}: #{count}"
    end
  end
end
