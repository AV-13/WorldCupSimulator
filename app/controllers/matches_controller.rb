class MatchesController < ApplicationController
  def show
    @simulation = Simulation.find_by!(token: params[:token])
    @match = Match.includes(:group, home_team: [:players, :coach], away_team: [:players, :coach]).find(params[:id])

    @prediction = Prediction.find_or_initialize_by(
      simulation_id: @simulation.id,
      match_id: @match.id
    )

    # Generate lineup data for both teams
    @home_lineup = generate_lineup(@match.home_team)
    @away_lineup = generate_lineup(@match.away_team)
  end

  def update
    @simulation = Simulation.find_by!(token: params[:token])
    @match = Match.includes(:group).find(params[:id])

    @prediction = Prediction.find_or_initialize_by(
      simulation_id: @simulation.id,
      match_id: @match.id
    )

    if @prediction.update(prediction_params)
      # Find next unpredicted match in this group
      next_match = find_next_unpredicted_match(@match.group)

      if next_match
        redirect_to match_path(@simulation.token, next_match.id), notice: t('flash.score_saved')
      else
        redirect_to group_path(@simulation.token, @match.group.name), notice: t('flash.score_saved')
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def prediction_params
    params.require(:prediction).permit(:home_score, :away_score)
  end

  def find_next_unpredicted_match(group)
    # Get all matches in this group
    group_matches = Match.where(group_id: group.id, stage: "group_stage").order(:id)

    # Get IDs of matches that already have predictions
    predicted_match_ids = Prediction
      .where(simulation_id: @simulation.id, match_id: group_matches.pluck(:id))
      .where.not(home_score: nil)
      .pluck(:match_id)

    # Find first match without a prediction
    group_matches.where.not(id: predicted_match_ids).first
  end

  def generate_lineup(team)
    {
      formation: "4-3-3",
      coach: coach_data(team),
      starters: starters_data(team)
    }
  end

  def coach_data(team)
    if team.coach
      { name: team.coach.full_name, fm_uid: team.coach.fm_uid, face_image: team.coach.face_image_path }
    else
      { name: "Unknown", fm_uid: nil, face_image: nil }
    end
  end

  def starters_data(team)
    starters = team.players.starters.order(:grid_row, :grid_col)
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
end
