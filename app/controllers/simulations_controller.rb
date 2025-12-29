class SimulationsController < ApplicationController
  def start
    # Always create a new simulation with the selected mode
    mode = params[:mode].presence || "complete"
    mode = "complete" unless Simulation::MODES.key?(mode)

    sim = Simulation.create!(pseudo: "Invite", mode: mode)
    cookies.signed[:simulation_token] = {
      value: sim.token,
      expires: 6.months.from_now,
      httponly: true
    }

    redirect_to simulation_path(sim.token)
  end

  def show
    @simulation = Simulation.find_by!(token: params[:token])
    cookies.signed[:simulation_token] = {
      value: @simulation.token,
      expires: 6.months.from_now,
      httponly: true
    }
    @groups = Group.order(:name)

    # Calculate progress
    @group_progress = calculate_group_progress
  end

  private

  def calculate_group_progress
    total_matches = Match.group_stage.count
    completed = Prediction.joins(:match)
                          .where(simulation: @simulation)
                          .where(matches: { stage: "group_stage" })
                          .where.not(home_score: nil)
                          .count

    { completed: completed, total: total_matches }
  end
end
