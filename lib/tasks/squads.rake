namespace :squads do
  # Mapping for ISO codes that differ between JSON and database
  ISO_CODE_MAPPING = {
    "en" => "gb-eng",  # England
    "wl" => "gb-wls",  # Wales
    "sc" => "gb-sct"   # Scotland (if needed)
  }.freeze

  desc "Import squads from JSON file"
  task import: :environment do
    # Idempotent - skip if players already exist
    if Player.exists?
      puts "✅ Squads already imported (#{Player.count} players, #{Coach.count} coaches). Skipping."
      next
    end

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

  desc "Match coach images with fm_uid based on first/last name"
  task match_coach_images: :environment do
    # Idempotent - skip if coaches already have fm_uid
    if Coach.where.not(fm_uid: nil).exists?
      puts "✅ Coach images already matched. Skipping."
      next
    end

    coaches_dir = Rails.root.join("app/assets/images/coach")

    unless coaches_dir.exist?
      puts "❌ Coach images directory not found: #{coaches_dir}"
      exit 1
    end

    # Build index from image files: { "firstname_lastname" => fm_uid }
    image_index = {}
    Dir.glob(coaches_dir.join("*.png")).each do |file|
      filename = File.basename(file, ".png")
      # Format: Country_FirstName_LastName_fmuid (e.g., Argentina_Lionel_Scaloni_2000219)
      parts = filename.split("_")
      next if parts.size < 4

      fm_uid = parts.last
      # Handle multi-word first/last names: everything between country and fm_uid
      name_parts = parts[1..-2]
      # Try different splits for first/last name
      name_parts.each_with_index do |_, i|
        next if i == 0 && name_parts.size > 1
        first_name = name_parts[0...i].join(" ")
        last_name = name_parts[i..-1].join(" ")
        key = "#{first_name.downcase}_#{last_name.downcase}".gsub(/\s+/, "_")
        image_index[key] = fm_uid
      end
      # Also try single first name, rest is last name
      if name_parts.size >= 2
        key = "#{name_parts[0].downcase}_#{name_parts[1..-1].join('_').downcase}"
        image_index[key] = fm_uid
      end
    end

    matched = 0
    not_matched = []

    Coach.find_each do |coach|
      # Try to match with various key formats
      keys_to_try = [
        "#{coach.first_name}_#{coach.last_name}".downcase.gsub(/\s+/, "_"),
        "#{coach.first_name.split.first}_#{coach.last_name}".downcase.gsub(/\s+/, "_"),
        "#{coach.last_name}".downcase.gsub(/\s+/, "_")
      ]

      fm_uid = nil
      keys_to_try.each do |key|
        if image_index[key]
          fm_uid = image_index[key]
          break
        end
      end

      if fm_uid
        coach.update!(fm_uid: fm_uid)
        puts "✓ #{coach.full_name} -> #{fm_uid}"
        matched += 1
      else
        not_matched << coach
      end
    end

    puts ""
    puts "=" * 50
    puts "Matched: #{matched}"
    puts "Not matched: #{not_matched.size}"

    if not_matched.any?
      puts ""
      puts "⚠️  Coaches without image match:"
      not_matched.each { |c| puts "  - #{c.team.name}: #{c.full_name}" }
    end

    # Reload the index
    Coach.reload_face_images_index!
    puts ""
    puts "✓ Coach face images index reloaded"
  end
end
