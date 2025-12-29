# db/seeds.rb

puts "🗑️  Nettoyage de la base de données..."
Prediction.destroy_all
Match.destroy_all
Team.destroy_all
Group.destroy_all
Simulation.destroy_all

puts "🌱 Démarrage du Seeding pour la Coupe du Monde 2026 (48 équipes)..."

# Coupe du Monde 2026 – Groupes issus du tirage (05/12/2025)
# Pour les places "barrage/playoff", on met 1 équipe au hasard parmi les prétendants listés.
# Format : [Nom du pays, Code ISO / code utilisé par votre front pour les drapeaux]
world_cup_data = {
  "A" => [
    ["Mexique", "mx"],
    ["Afrique du Sud", "za"],
    ["Corée du Sud", "kr"],
    ["Danemark", "dk"] # UEFA Playoff D (Denmark, North Macedonia, Czechia, Ireland)
  ],
  "B" => [
    ["Canada", "ca"],
    ["Italie", "it"],   # UEFA Playoff A (Italy, Northern Ireland, Wales, Bosnia & Herzegovina)
    ["Qatar", "qa"],
    ["Suisse", "ch"]
  ],
  "C" => [
    ["Brésil", "br"],
    ["Maroc", "ma"],
    ["Haïti", "ht"],
    ["Écosse", "gb-sct"]
  ],
  "D" => [
    ["États-Unis", "us"],
    ["Paraguay", "py"],
    ["Australie", "au"],
    ["Turquie", "tr"] # UEFA Playoff C (Türkiye, Romania, Slovakia, Kosovo)
  ],
  "E" => [
    ["Allemagne", "de"],
    ["Curaçao", "cw"],
    ["Côte d'Ivoire", "ci"],
    ["Équateur", "ec"]
  ],
  "F" => [
    ["Pays-Bas", "nl"],
    ["Japon", "jp"],
    ["Ukraine", "ua"],  # UEFA Playoff B (Ukraine, Sweden, Poland, Albania)
    ["Tunisie", "tn"]
  ],
  "G" => [
    ["Belgique", "be"],
    ["Égypte", "eg"],
    ["Iran", "ir"],
    ["Nouvelle-Zélande", "nz"]
  ],
  "H" => [
    ["Espagne", "es"],
    ["Cap-Vert", "cv"],
    ["Arabie Saoudite", "sa"],
    ["Uruguay", "uy"]
  ],
  "I" => [
    ["France", "fr"],
    ["Sénégal", "sn"],
    ["Irak", "iq"],     # Intercontinental Playoff Tournament 2 (Bolivia, Suriname, Iraq)
    ["Norvège", "no"]
  ],
  "J" => [
    ["Argentine", "ar"],
    ["Algérie", "dz"],
    ["Autriche", "at"],
    ["Jordanie", "jo"]
  ],
  "K" => [
    ["Portugal", "pt"],
    ["RD Congo", "cd"], # Intercontinental Playoff Tournament 1 (Jamaica, New Caledonia, DR Congo)
    ["Ouzbékistan", "uz"],
    ["Colombie", "co"]
  ],
  "L" => [
    ["Angleterre", "gb-eng"],
    ["Croatie", "hr"],
    ["Ghana", "gh"],
    ["Panama", "pa"]
  ]
}

# Boucle principale pour créer Groupes, Équipes et Matchs
world_cup_data.each do |group_name, teams_list|
  group = Group.create!(name: group_name)
  puts "🏆 Groupe #{group.name} créé."

  current_teams = teams_list.map do |name, iso|
    Team.create!(
      name: name,
      iso_code: iso,
      group_id: group.id # ✅ évite l'erreur si belongs_to :group n'est pas encore déclaré
    )
  end

  # Matchs de poule : tout le monde contre tout le monde
  current_teams.combination(2).each do |home, away|
    Match.create!(
      group_id: group.id,         # ✅ idem
      home_team_id: home.id,       # ✅ évite l'erreur si belongs_to :home_team n'est pas encore déclaré
      away_team_id: away.id,       # ✅ évite l'erreur si belongs_to :away_team n'est pas encore déclaré
      stage: "group_stage"
    )
  end
end

puts "------------------------------------------------"
puts "Terminé."
puts "Bilan :"
puts "   - #{Group.count} Groupes (A-L)"
puts "   - #{Team.count} Équipes"
puts "   - #{Match.count} Matchs de poule générés"
puts "------------------------------------------------"
