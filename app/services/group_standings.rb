class GroupStandings
  Row = Struct.new(
    :team,
    :played, :wins, :draws, :losses,
    :goals_for, :goals_against,
    keyword_init: true
  ) do
    def goal_diff = goals_for - goals_against
    def points = (wins * 3) + draws
  end

  def initialize(simulation:, group:)
    @simulation = simulation
    @group = group
  end

  def call
    teams = @group.teams.to_a

    rows = teams.index_with do |team|
      Row.new(
        team: team,
        played: 0, wins: 0, draws: 0, losses: 0,
        goals_for: 0, goals_against: 0
      )
    end

    matches = Match
                .where(group_id: @group.id, stage: "group_stage")
                .includes(:home_team, :away_team)

    predictions_by_match_id = Prediction
                                .where(simulation_id: @simulation.id, match_id: matches.map(&:id))
                                .index_by(&:match_id)

    matches.each do |match|
      pred = predictions_by_match_id[match.id]
      next if pred.nil?
      next if pred.home_score.nil? || pred.away_score.nil?

      home = rows[match.home_team]
      away = rows[match.away_team]
      next if home.nil? || away.nil? # sécurité

      hs = pred.home_score
      as = pred.away_score

      home.played += 1
      away.played += 1

      home.goals_for += hs
      home.goals_against += as
      away.goals_for += as
      away.goals_against += hs

      if hs > as
        home.wins += 1
        away.losses += 1
      elsif hs < as
        away.wins += 1
        home.losses += 1
      else
        home.draws += 1
        away.draws += 1
      end
    end

    # Tri "classique" : Points > Diff > Buts pour > Nom
    rows.values.sort_by do |r|
      [-r.points, -r.goal_diff, -r.goals_for, r.team.name]
    end
  end
end
