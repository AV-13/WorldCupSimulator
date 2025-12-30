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
    @groups = Group.includes(:teams).order(:name)

    # Calculate progress
    @group_progress = calculate_group_progress

    # Calculate standings for each group
    @group_standings = {}
    @group_completion = {}
    @groups.each do |group|
      standings = GroupStandings.new(simulation: @simulation, group: group).call
      @group_standings[group.id] = standings

      # Check if group is complete (all matches have predictions)
      group_matches = Match.where(group: group, stage: "group_stage")
      completed_predictions = Prediction.where(simulation: @simulation, match: group_matches)
                                        .where.not(home_score: nil).count
      @group_completion[group.id] = completed_predictions == group_matches.count && group_matches.count > 0
    end

    # Check if all groups are complete (for third place selection)
    @all_groups_complete = @group_completion.values.all?
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
