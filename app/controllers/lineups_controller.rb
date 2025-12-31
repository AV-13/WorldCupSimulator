class LineupsController < ApplicationController
  before_action :load_simulation
  before_action :load_team
  before_action :load_match

  def show
    @lineup = generate_lineup
    @opponent = find_opponent
  end

  private

  def load_simulation
    @simulation = Simulation.find_by!(token: params[:token])
  end

  def load_team
    @team = Team.includes(:players, :coach).find(params[:team_id])
  end

  def load_match
    @match = Match.find_by(id: params[:match_id]) if params[:match_id].present?
  end

  def find_opponent
    return nil unless @match
    @match.home_team_id == @team.id ? @match.away_team : @match.home_team
  end

  def generate_lineup
    {
      formation: "4-3-3",
      coach: coach_data,
      starters: starters_data,
      substitutes: substitutes_data
    }
  end

  def coach_data
    if @team.coach
      {
        name: @team.coach.full_name,
        first_name: @team.coach.first_name,
        last_name: @team.coach.last_name
      }
    else
      { name: "Unknown", first_name: "Unknown", last_name: "Coach" }
    end
  end

  def starters_data
    starters = @team.players.starters.order(:grid_row, :grid_col)
    return fallback_starters if starters.empty?

    starters.map do |player|
      {
        number: player.jersey_number,
        first_name: player.first_name,
        last_name: player.last_name,
        position: player.position,
        grid_row: player.grid_row,
        grid_col: player.grid_col,
        fm_uid: player.fm_uid,
        face_image: player.face_image_path
      }
    end
  end

  def substitutes_data
    subs = @team.players.substitutes.order(:jersey_number)
    return fallback_substitutes if subs.empty?

    subs.map do |player|
      {
        number: player.jersey_number,
        first_name: player.first_name,
        last_name: player.last_name,
        position: player.position,
        fm_uid: player.fm_uid,
        face_image: player.face_image_path
      }
    end
  end

  def fallback_starters
    [
      { number: 1,  first_name: "Player", last_name: "1",  position: "GK",  grid_row: 1, grid_col: 3, face_image: nil },
      { number: 2,  first_name: "Player", last_name: "2",  position: "RB",  grid_row: 2, grid_col: 5, face_image: nil },
      { number: 3,  first_name: "Player", last_name: "3",  position: "CB",  grid_row: 2, grid_col: 4, face_image: nil },
      { number: 4,  first_name: "Player", last_name: "4",  position: "CB",  grid_row: 2, grid_col: 2, face_image: nil },
      { number: 5,  first_name: "Player", last_name: "5",  position: "LB",  grid_row: 2, grid_col: 1, face_image: nil },
      { number: 6,  first_name: "Player", last_name: "6",  position: "CDM", grid_row: 3, grid_col: 2, face_image: nil },
      { number: 7,  first_name: "Player", last_name: "7",  position: "RW",  grid_row: 4, grid_col: 5, face_image: nil },
      { number: 8,  first_name: "Player", last_name: "8",  position: "CM",  grid_row: 3, grid_col: 3, face_image: nil },
      { number: 9,  first_name: "Player", last_name: "9",  position: "ST",  grid_row: 4, grid_col: 3, face_image: nil },
      { number: 10, first_name: "Player", last_name: "10", position: "CAM", grid_row: 3, grid_col: 4, face_image: nil },
      { number: 11, first_name: "Player", last_name: "11", position: "LW",  grid_row: 4, grid_col: 1, face_image: nil }
    ]
  end

  def fallback_substitutes
    (12..23).map do |n|
      { number: n, first_name: "Sub", last_name: n.to_s, position: "SUB", face_image: nil }
    end
  end
end
