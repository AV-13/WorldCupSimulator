class PagesController < ApplicationController
  def home
    # Show resume toaster if user has an existing simulation
    if @current_simulation_token.present?
      simulation = Simulation.find_by(token: @current_simulation_token)
      @show_resume_toaster = simulation.present?
    end
  end

  def teams
    @teams = Team.includes(:group, :coach, players: [])
                 .order("groups.name", :name)
    @teams_by_group = @teams.group_by(&:group)
    @groups = Group.order(:name)

    # Preselect team from params or default to first team
    @selected_team = if params[:team_id].present?
                       @teams.find { |t| t.id == params[:team_id].to_i } || @teams.first
                     else
                       @teams.first
                     end
    @players_by_position = @selected_team&.players&.group_by(&:position) || {}

    # Show resume toaster if user has an existing simulation
    if @current_simulation_token.present?
      simulation = Simulation.find_by(token: @current_simulation_token)
      @show_resume_toaster = simulation.present?
    end
  end

  def team_detail
    @team = Team.includes(:group, :coach, :players).find(params[:id])
    @players_by_position = @team.players.group_by(&:position)

    render partial: "team_details", locals: { team: @team, players_by_position: @players_by_position }, layout: false
  end

  def legal
  end

  def privacy
  end
end
