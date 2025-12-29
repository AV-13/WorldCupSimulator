class MatchesController < ApplicationController
  def show
    @simulation = Simulation.find_by!(token: params[:token])
    @match = Match.includes(:group, :home_team, :away_team).find(params[:id])

    @prediction = Prediction.find_or_initialize_by(
      simulation_id: @simulation.id,
      match_id: @match.id
    )
  end

  def update
    @simulation = Simulation.find_by!(token: params[:token])
    @match = Match.find(params[:id])

    @prediction = Prediction.find_or_initialize_by(
      simulation_id: @simulation.id,
      match_id: @match.id
    )

    if @prediction.update(prediction_params)
      redirect_to match_path(@simulation.token, @match.id), notice: "Score enregistré ✅"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def prediction_params
    params.require(:prediction).permit(:home_score, :away_score)
  end
end
