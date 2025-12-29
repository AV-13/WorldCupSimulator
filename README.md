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
