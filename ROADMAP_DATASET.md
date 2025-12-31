# World Cup Simulator 2026

A web application that allows users to simulate the FIFA World Cup 2026 by predicting match scores and seeing how their predictions affect group standings and tournament outcomes.

## Overview

World Cup Simulator lets you create your own tournament simulation where you can:
- Predict scores for all matches
- See real-time group standings based on your predictions
- Share your simulation with friends via a unique URL
- Track your predictions throughout the tournament

Each user gets a unique simulation token, allowing multiple people to create and compare their own tournament predictions.

## Technical Stack

### Core Framework
- **Ruby** 3.4.3
- **Rails** 8.1.1
- **Database** SQLite3

### Frontend
- **Turbo Rails** - SPA-like page acceleration without writing JavaScript
- **Stimulus** - Modest JavaScript framework for interactivity
- **Importmap Rails** - Modern ESM import maps (no Node.js required)
- **Propshaft** - Modern asset pipeline

### Background Processing & Caching
- **Solid Cache** - Database-backed caching
- **Solid Queue** - Database-backed job queue
- **Solid Cable** - Database-backed Action Cable adapter

### Deployment
- **Kamal** - Zero-downtime Docker deployments
- **Puma** - High-performance web server
- **Thruster** - HTTP asset caching and compression

### Code Quality
- **RuboCop** - Ruby linter (Omakase style)
- **Brakeman** - Security vulnerability scanner
- **Bundler Audit** - Dependency security checker

## Getting Started

### Prerequisites
- Ruby 3.4.3
- Bundler

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/WorldCupSimulator.git
cd WorldCupSimulator
```

2. Install dependencies:
```bash
bundle install
```

3. Setup the database:
```bash
bin/rails db:setup
```

4. Seed the database with World Cup data:
```bash
bin/rails db:seed
```

5. Start the server:
```bash
bin/dev
```

6. Visit `http://localhost:3000` in your browser.

## Project Structure

```
app/
├── controllers/
│   ├── application_controller.rb  # Base controller with simulation helper
│   ├── groups_controller.rb       # Group standings and matches
│   ├── matches_controller.rb      # Match predictions
│   ├── pages_controller.rb        # Landing page
│   └── simulations_controller.rb  # Simulation management
├── models/
│   ├── group.rb                   # Tournament groups (A, B, C, etc.)
│   ├── match.rb                   # Matches between teams
│   ├── prediction.rb              # User score predictions
│   ├── simulation.rb              # User simulation session
│   └── team.rb                    # National teams
├── services/
│   └── group_standings.rb         # Standings calculation logic
└── views/
    ├── groups/                    # Group detail views
    ├── matches/                   # Match prediction forms
    ├── pages/                     # Landing page
    └── simulations/               # Simulation overview
```

## Data Model

```
Simulation (user session)
  └── has_many Predictions

Group (A, B, C, etc.)
  ├── has_many Teams
  └── has_many Matches

Match
  ├── belongs_to home_team (Team)
  ├── belongs_to away_team (Team)
  └── belongs_to Group

Prediction
  ├── belongs_to Simulation
  ├── belongs_to Match
  ├── home_score (integer)
  └── away_score (integer)
```

## Features

### Simulation Sessions
- Automatic session creation for new visitors
- Signed cookies for secure session persistence (6-month expiry)
- Shareable URLs (`/s/:token`) for comparing predictions

### Standings Calculation
- Real-time standings based on entered predictions
- Standard FIFA point system (Win: 3 pts, Draw: 1 pt, Loss: 0 pts)
- Tiebreakers: Points > Goal Difference > Goals For > Alphabetical

### User Experience
- Clean, simple interface
- Mobile-friendly design
- No account creation required

## Running Tests

```bash
bin/rails test
```

## Code Quality

```bash
# Run RuboCop
bin/rubocop

# Security scan
bin/brakeman

# Dependency audit
bundle exec bundler-audit
```

## License

This project is open source and available under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


# Roadmap : Dataset Joueurs - World Cup 2026 Simulator

## Contexte Projet

Ce document décrit le plan d'implémentation pour ajouter les **vrais joueurs** au simulateur existant.

**Stack du simulateur de coupe du monde :**
- Ruby on Rails 8.1
- SQLite (développement)
- Assets existants : `player_placeholder.jpg`, `football_pitch.jpg`
- Feature Lineup déjà implémentée avec données fictives

**Modèles existants :**
- `Team` (48 équipes, liées aux `Group`)
- `Match` (72 matchs de poule + 32 matchs K.O.)
- `Simulation` / `Prediction`

---

## Architecture : Séparation des responsabilités

```
┌─────────────────────────────────┐      ┌─────────────────────────────────┐
│      PROJET PYTHON              │      │      PROJET RAILS               │
│      (Data Pipeline)            │      │      (Simulateur)               │
├─────────────────────────────────┤      ├─────────────────────────────────┤
│ • Scraping FotMob               │      │ • Import JSON final             │
│ • Matching FM UIDs              │      │ • Modèles Player/Coach          │
│ • Nettoyage des données         │ ──►  │ • Copie des faces               │
│ • Export JSON structuré         │      │ • Affichage Lineup              │
│ • Tri des faces (optionnel)     │      │                                 │
└─────────────────────────────────┘      └─────────────────────────────────┘
```

---

## Partie 1 : Projet Python (à part)

### 1.1 Objectif
Produire un fichier JSON propre avec tous les joueurs des 48 nations.

### 1.2 Format de sortie attendu

```json
// db/seeds/data/world_cup_squads.json
{
  "teams": [
    {
      "name": "France",
      "iso_code": "fr",
      "coach": {
        "first_name": "Didier",
        "last_name": "Deschamps"
      },
      "players": [
        {
          "fm_uid": "123456",
          "first_name": "Kylian",
          "last_name": "Mbappé",
          "position": "ST",
          "jersey_number": 10,
          "club": "Real Madrid",
          "birth_date": "1998-12-20",
          "is_starter": true,
          "grid_row": 4,
          "grid_col": 3
        },
        // ... 22-25 autres joueurs
      ]
    },
    // ... 47 autres équipes
  ]
}
```

### 1.3 Champs requis par joueur

| Champ | Type | Obligatoire | Notes |
|-------|------|-------------|-------|
| `fm_uid` | string | Non | Pour lier aux faces FM |
| `first_name` | string | Oui | |
| `last_name` | string | Oui | |
| `position` | string | Oui | GK, CB, RB, LB, CDM, CM, CAM, RW, LW, ST... |
| `jersey_number` | integer | Oui | 1-99 |
| `club` | string | Non | Club actuel |
| `birth_date` | string | Non | Format ISO (YYYY-MM-DD) |
| `is_starter` | boolean | Oui | true pour les 11 titulaires |
| `grid_row` | integer | Oui si starter | 1-4 (1=gardien, 4=attaque) |
| `grid_col` | integer | Oui si starter | 1-5 (gauche à droite) |

### 1.4 Grille de positionnement (4-3-3)

```
        Col 1   Col 2   Col 3   Col 4   Col 5
Row 4   LW              ST              RW
Row 3           CM      CAM     CM
Row 2   LB      CB              CB      RB
Row 1                   GK
```

---

## Partie 2 : Projet Rails (ce repo)

### 2.1 Migrations à créer

```bash
bin/rails generate model Player \
  team:references \
  fm_uid:string \
  first_name:string \
  last_name:string \
  position:string \
  jersey_number:integer \
  birth_date:date \
  club:string \
  is_starter:boolean \
  grid_row:integer \
  grid_col:integer

bin/rails generate model Coach \
  team:references \
  first_name:string \
  last_name:string

bin/rails db:migrate
```

### 2.2 Rake Task d'import

```ruby
# lib/tasks/squads.rake
namespace :squads do
  desc "Import squads from JSON file"
  task import: :environment do
    data = JSON.parse(File.read(Rails.root.join("db/seeds/data/world_cup_squads.json")))

    data["teams"].each do |team_data|
      team = Team.find_by!(iso_code: team_data["iso_code"])

      # Coach
      if team_data["coach"]
        team.create_coach!(
          first_name: team_data["coach"]["first_name"],
          last_name: team_data["coach"]["last_name"]
        )
      end

      # Players
      team_data["players"].each do |p|
        team.players.create!(
          fm_uid: p["fm_uid"],
          first_name: p["first_name"],
          last_name: p["last_name"],
          position: p["position"],
          jersey_number: p["jersey_number"],
          club: p["club"],
          birth_date: p["birth_date"],
          is_starter: p["is_starter"],
          grid_row: p["grid_row"],
          grid_col: p["grid_col"]
        )
      end

      puts "✓ #{team.name}: #{team_data['players'].size} players"
    end
  end

  desc "Copy face images from FM facepack"
  task copy_faces: :environment do
    source_dir = ENV.fetch("FM_FACES_DIR", "~/fm_faces")
    target_dir = Rails.root.join("app/assets/images/faces")

    FileUtils.mkdir_p(target_dir)

    Player.where.not(fm_uid: [nil, ""]).find_each do |player|
      source = File.expand_path("#{source_dir}/#{player.fm_uid}.png")
      target = target_dir.join("#{player.fm_uid}.png")

      FileUtils.cp(source, target) if File.exist?(source) && !File.exist?(target)
    end

    puts "✓ Done"
  end
end
```

### 2.3 Utilisation

```bash
# 1. Placer le JSON généré par Python
cp ~/python-project/output/world_cup_squads.json db/seeds/data/

# 2. Importer les données
bin/rails squads:import

# 3. Copier les faces (optionnel)
FM_FACES_DIR=~/fm_faces bin/rails squads:copy_faces
```

---

## Checklist

### Projet Python (à faire de ton côté)
- [ ] Scraping FotMob / autre source
- [ ] Matching avec FM UIDs
- [ ] Nettoyage et validation
- [ ] Export JSON au format attendu
- [ ] (Optionnel) Extraire les faces utiles du facepack

### Projet Rails (quand les données sont prêtes)
- [ ] Créer migrations Player + Coach
- [ ] Créer rake task `squads:import`
- [ ] Créer rake task `squads:copy_faces`
- [ ] Mettre à jour `LineupsController`
- [ ] Mettre à jour la vue `lineups/show.html.erb`

---

## Notes

- Le JSON doit matcher les `iso_code` existants dans la table `teams`
- Les `grid_row` et `grid_col` ne sont nécessaires que pour les 11 starters
- Si pas de `fm_uid`, le placeholder sera utilisé
- Tu peux aussi exporter les faces extraites dans un dossier séparé côté Python pour éviter de manipuler les 30 Go
