class PagesController < ApplicationController
  def home
    # Show resume toaster if user has an existing simulation
    if @current_simulation_token.present?
      simulation = Simulation.find_by(token: @current_simulation_token)
      @show_resume_toaster = simulation.present?
    end
  end

  def teams
    # Future page - list all 48 teams with their squads
    @teams = Team.includes(:group).order("groups.name", :name)
  end
end
