# World Cup Simulator 2026 - Roadmap

This document outlines the development progress and future plans for the World Cup Simulator.

---

## Completed Features

### Phase 1: Project Foundation
- [x] Initialize Rails 8.1.1 project with modern tooling
- [x] Configure SQLite database with Solid Cache/Queue/Cable
- [x] Set up Turbo and Stimulus for frontend interactivity
- [x] Configure Kamal for Docker deployment
- [x] Set up code quality tools (RuboCop, Brakeman)

### Phase 2: Core Data Model
- [x] Create `Group` model for tournament groups
- [x] Create `Team` model with group associations
- [x] Create `Match` model linking home/away teams and groups
- [x] Create `Simulation` model with unique token generation
- [x] Create `Prediction` model linking simulations to match scores
- [x] Set up all database migrations and indexes

### Phase 3: Simulation System
- [x] Implement simulation token generation
- [x] Create signed cookie-based session management
- [x] Build simulation start/resume flow
- [x] Implement shareable simulation URLs (`/s/:token`)

### Phase 4: Group Stage
- [x] Build group listing in simulation view
- [x] Create group detail page with team list
- [x] Display matches within each group
- [x] Implement `GroupStandings` service for standings calculation
- [x] Add standings table with proper sorting (points, goal diff, goals for)

### Phase 5: Match Predictions
- [x] Create match detail view
- [x] Build score prediction form
- [x] Implement prediction save/update functionality
- [x] Display current predictions in group view

---

## In Progress

### Phase 6: UI/UX Improvements
- [ ] Add CSS styling and visual design
- [ ] Implement responsive mobile layout
- [ ] Add team flags/icons display
- [ ] Create navigation header/footer
- [ ] Add loading states and transitions

---

## Upcoming Features

### Phase 7: Complete 2026 World Cup Data
- [ ] Seed all 48 qualified teams with ISO codes
- [ ] Create all 12 groups (A through L)
- [ ] Generate all 144 group stage matches
- [ ] Add team strength/ranking data for AI predictions

### Phase 8: Knockout Stage
- [ ] Create Round of 32 bracket structure
- [ ] Implement Round of 16 matches
- [ ] Add Quarter-finals
- [ ] Add Semi-finals
- [ ] Add Third-place playoff
- [ ] Add Final match
- [ ] Build bracket visualization

### Phase 9: Automatic Qualification
- [ ] Calculate group winners and runners-up from standings
- [ ] Determine best third-place teams (new 2026 format)
- [ ] Auto-populate knockout matches based on predictions
- [ ] Handle knockout tiebreakers (extra time, penalties)

### Phase 10: Enhanced Predictions
- [ ] Add prediction confidence levels
- [ ] Implement "quick fill" with random scores
- [ ] Add AI-suggested predictions based on team rankings
- [ ] Import predictions from external sources

### Phase 11: Statistics & Analytics
- [ ] Show top scorers based on predictions
- [ ] Display team statistics (goals scored/conceded)
- [ ] Create tournament summary dashboard
- [ ] Add prediction accuracy tracking (post-tournament)

### Phase 12: Social Features
- [ ] User accounts (optional, for persistence)
- [ ] Compare simulations between users
- [ ] Leaderboard for prediction accuracy
- [ ] Share simulation on social media
- [ ] Embed simulation widget

### Phase 13: Real-Time Features
- [ ] Live match score updates during tournament
- [ ] WebSocket notifications for match results
- [ ] Real-time standings recalculation
- [ ] Push notifications for upcoming matches

### Phase 14: Advanced Features
- [ ] Multiple tournament support (past World Cups)
- [ ] Custom tournament creation
- [ ] Export predictions to PDF/image
- [ ] API for third-party integrations
- [ ] PWA support for offline access

---

## Technical Debt & Improvements

### Code Quality
- [ ] Increase test coverage (models, controllers, services)
- [ ] Add integration tests with Capybara
- [ ] Add request specs for all endpoints
- [ ] Document API endpoints

### Performance
- [ ] Add database indexes for common queries
- [ ] Implement caching for standings calculations
- [ ] Optimize N+1 queries in group/match loading
- [ ] Add pagination for large data sets

### Security
- [ ] Add rate limiting for prediction updates
- [ ] Implement CSRF protection review
- [ ] Add input sanitization for scores
- [ ] Security audit with Brakeman

### Infrastructure
- [ ] Set up CI/CD pipeline
- [ ] Configure production environment
- [ ] Add monitoring and error tracking
- [ ] Set up automated backups

---

## 2026 World Cup Specifics

The FIFA World Cup 2026 introduces a new format:

| Aspect | Details |
|--------|---------|
| **Teams** | 48 (expanded from 32) |
| **Groups** | 12 groups of 4 teams |
| **Group Matches** | 144 total (6 per group) |
| **Knockout Round** | Round of 32 (new), R16, QF, SF, 3rd place, Final |
| **Host Countries** | USA, Canada, Mexico |
| **Total Matches** | 104 matches |

### Tournament Structure
```
Group Stage (48 teams in 12 groups)
         │
         ▼
   Round of 32 (32 teams)
         │
         ▼
   Round of 16 (16 teams)
         │
         ▼
   Quarter-finals (8 teams)
         │
         ▼
   Semi-finals (4 teams)
         │
         ▼
   Third Place + Final
```

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 0.1.0 | TBD | Initial release with group stage predictions |
| 0.2.0 | TBD | Knockout stage support |
| 0.3.0 | TBD | Full 2026 World Cup data |
| 1.0.0 | TBD | Production-ready release |

---

## Contributing

Want to help? Check out the issues labeled `good first issue` or pick any item from the roadmap above!
