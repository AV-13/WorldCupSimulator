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

  def recap
    @simulation = Simulation.find_by!(token: params[:token])
    @groups = Group.includes(:teams).order(:name)

    # Group stage progress
    @group_progress = calculate_group_progress
    @groups_completed = 0
    @groups_data = []

    @groups.each do |group|
      group_matches = Match.where(group: group, stage: "group_stage")
      completed = Prediction.where(simulation: @simulation, match: group_matches)
                            .where.not(home_score: nil).count
      total = group_matches.count
      is_complete = completed == total && total > 0

      @groups_completed += 1 if is_complete
      @groups_data << {
        group: group,
        completed: completed,
        total: total,
        is_complete: is_complete
      }
    end

    # Knockout stage progress
    knockout_matches = Match.knockout
    @knockout_progress = {
      completed: Prediction.where(simulation: @simulation, match: knockout_matches)
                           .where.not(home_score: nil).count,
      total: knockout_matches.count
    }

    # Determine next action
    @next_action = determine_next_action
  end

  private

  def determine_next_action
    # Find first incomplete group
    incomplete_group = @groups_data.find { |g| !g[:is_complete] }

    if incomplete_group
      if @simulation.quick_mode?
        { path: quick_group_path(token: @simulation.token, name: incomplete_group[:group].name),
          label_key: "recap.continue_group", group: incomplete_group[:group].name }
      else
        { path: group_path(@simulation.token, incomplete_group[:group].name),
          label_key: "recap.continue_group", group: incomplete_group[:group].name }
      end
    elsif @knockout_progress[:completed] < @knockout_progress[:total]
      if @simulation.quick_mode?
        { path: quick_bracket_path(token: @simulation.token),
          label_key: "recap.continue_bracket" }
      else
        { path: bracket_path(token: @simulation.token),
          label_key: "recap.continue_bracket" }
      end
    else
      { path: celebration_path(token: @simulation.token),
        label_key: "recap.view_results" }
    end
  end

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
