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

### 2. Group Stage
- [x] Seed 48 teams and 12 groups (official draw)
- [x] Generate 72 group stage matches
- [x] Display groups and teams
- [x] Match score input
- [x] Standings calculation (points, goal diff, goals for)
- [ ] Team flags display

### 3. Knockout Stage
- [ ] Data model for knockout matches
- [ ] Automatic qualification calculation (1st, 2nd, best 3rd places)
- [ ] Round of 32 (32 teams)
- [ ] Round of 16 (16 teams)
- [ ] Quarter-finals (8 teams)
- [ ] Semi-finals (4 teams)
- [ ] Third-place match
- [ ] Final
- [ ] Score input for each round
- [ ] Extra time / penalties indicator

### 4. Bracket Visualization
- [ ] Full tournament bracket view
- [ ] Navigation between stages
- [ ] Winner display

### 5. Basic UI
- [ ] CSS styling and layout
- [ ] Responsive mobile version
- [ ] Clear navigation between views

---

## Current Status

**Working:**
- Create a simulation and get a shareable link
- View all 12 groups with their 4 teams
- Enter group stage match scores
- See standings update automatically

**Missing for usable MVP:**
- Entire knockout stage (Round of 32 → Final)
- Tournament bracket view
- Basic styling

---

## Future Improvements (post-MVP)

### User Experience
- [ ] Quick fill (random scores)
- [ ] Suggestions based on FIFA rankings
- [ ] Statistics (top scorers, goals per team)
- [ ] Export to image/PDF

### Social Features
- [ ] User accounts (optional)
- [ ] Compare simulations between users
- [ ] Accuracy leaderboard (after actual tournament)
- [ ] Social media sharing

### Technical
- [ ] Automated tests
- [ ] CI/CD pipeline
- [ ] Production deployment

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
