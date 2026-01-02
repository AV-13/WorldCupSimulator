# World Cup Simulator 2026 - Roadmap

Prediction simulator for the 2026 FIFA World Cup.

---

## MVP - Core Features

### 1. Technical Infrastructure
- [x] Rails 8 project initialized
- [x] SQLite database configured
- [x] Data models (Group, Team, Match, Simulation, Prediction)
- [x] Signed cookie session system
- [x] Shareable URLs (`/s/:token`)
- [x] Turbo Streams for dynamic updates
- [x] Stimulus controllers for interactivity

### 2. Group Stage
- [x] Seed 48 teams and 12 groups (official draw December 2025)
- [x] Generate 72 group stage matches
- [x] Display groups and teams
- [x] Match score input (complete mode)
- [x] Standings calculation (points, goal diff, goals for)
- [x] Team flags display (flag-icons library)
- [x] Drag & drop ranking (quick mode)

### 3. Knockout Stage
- [x] Data model for knockout matches (round, match_number, home_source, away_source)
- [x] Automatic qualification calculation (1st, 2nd, best 3rd places)
- [x] **495 FIFA combinations table** for third place team assignments (Annex C)
- [x] Round of 32 (matches 49-64)
- [x] Round of 16 (matches 65-72)
- [x] Quarter-finals (matches 73-76)
- [x] Semi-finals (matches 77-78)
- [x] Third-place match (match 79)
- [x] Final (match 80)
- [x] Score input for each round (complete mode)
- [x] Click-to-select winner (quick mode with Turbo Streams)
- [x] Bracket progression (winner advances to next round)

### 4. Two Simulation Modes
- [x] **Complete mode**: Enter all scores manually, detailed predictions
- [x] **Quick mode**: Drag & drop group rankings, click winners in knockout
- [x] Mode selection on homepage
- [x] Manual third-place team selection (quick mode)

### 5. Basic UI
- [x] Functional views for all stages
- [x] Flag icons next to all team names
- [x] Color coding for qualification status (green/orange/red)
- [ ] Professional CSS styling
- [ ] Responsive mobile version

---

## Current Status

**Fully Working:**
- Create simulation with choice of mode (complete/quick)
- View all 12 groups with their 4 teams and flags
- Enter group stage match scores OR drag & drop rankings
- See standings update automatically
- Qualification calculation with 8 best third places
- 495 FIFA official combinations for bracket assignment
- Full knockout bracket (32 matches)
- Knockout predictions with bracket progression
- Turbo Streams for instant UI updates (no page reload)

**Ready for use** - Both modes functional end-to-end!

---

## Next Up

### Visual Bracket (Priority)
- [ ] Professional tournament bracket visualization
- [ ] CSS Grid layout for match positioning
- [ ] SVG connecting lines between rounds
- [ ] Stimulus controller for hover/click interactions
- [ ] Animations on winner selection
- [ ] Match cards with flags, scores, team names
- [ ] Responsive design (horizontal scroll on mobile)

**Technical approach:** CSS Grid + SVG + Stimulus (no D3.js)
- Perfect Turbo compatibility
- Lightweight (~5KB vs 250KB for D3)
- Full control over styling
- Native CSS animations

---

## Future Improvements (post-MVP)

### User Experience
- [ ] Quick fill with random scores
- [ ] Suggestions based on FIFA rankings
- [ ] Statistics dashboard (top scorers, goals per team)
- [ ] Export to image/PDF
- [ ] Dark mode

### Social Features
- [ ] User accounts (optional)
- [ ] Compare simulations between users
- [ ] Accuracy leaderboard (after actual tournament)
- [ ] Social media sharing with preview cards

### Technical
- [ ] Automated tests (RSpec)
- [ ] CI/CD pipeline (GitHub Actions)
- [x] Production deployment (Render + UptimeRobot)
- [ ] Performance optimization

---

## 2026 World Cup Format

| Aspect | Details |
|--------|---------|
| **Teams** | 48 (new format) |
| **Groups** | 12 groups of 4 |
| **Group matches** | 72 (6 per group) |
| **Qualifiers per group** | 1st + 2nd + 8 best 3rd places |
| **Knockout rounds** | R32, R16, QF, SF, 3rd place, Final |
| **Total matches** | 104 |
| **Host countries** | USA, Canada, Mexico |

---

## Implementation Details

### Services Architecture
- `GroupStandings` - Calculate group rankings with FIFA criteria
- `KnockoutQualification` - Determine 32 qualifying teams
- `ThirdPlaceCombinations` - Lookup FIFA Annex C combinations
- `KnockoutBracketGenerator` - Create knockout match structure
- `KnockoutProgression` - Update bracket as winners are determined
- `QuickRankingService` - Generate scores from ranking (quick mode)
- `QuickKnockoutService` - Set winner from click (quick mode)

### Key Files
- `db/seeds.rb` - 48 teams, 12 groups, 72 matches
- `app/services/third_place_combinations_data.rb` - 495 combinations
- `app/javascript/controllers/sortable_controller.js` - Drag & drop
- `app/helpers/application_helper.rb` - Flag icons helper
