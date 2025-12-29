class GroupsController < ApplicationController
  def show
    @simulation = Simulation.find_by!(token: params[:token])
    @group = Group.find_by!(name: params[:name])
    @teams = @group.teams.order(:name)
    @matches = Match.where(group_id: @group.id, stage: "group_stage").includes(:home_team, :away_team).order(:id)
    @predictions_by_match_id = Prediction
                                 .where(simulation_id: @simulation.id, match_id: @matches.map(&:id))
                                 .index_by(&:match_id)
    @standings = GroupStandings
                   .new(simulation: @simulation, group: @group)
                   .call
  end
end
