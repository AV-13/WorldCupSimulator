# frozen_string_literal: true

class KnockoutMatchesController < ApplicationController
  before_action :load_simulation
  before_action :load_match

  def show
    @prediction = Prediction.find_or_initialize_by(
      simulation: @simulation,
      match: @match
    )
  end

  def update
    @prediction = Prediction.find_or_initialize_by(
      simulation: @simulation,
      match: @match
    )

    if @prediction.update(prediction_params)
      # Update bracket progression after prediction
      KnockoutProgression.new(simulation: @simulation).update_from_match(@match.match_number)

      # Redirect to celebration page if final was just predicted
      if @match.match_number == 80
        redirect_to celebration_path(token: @simulation.token)
      else
        redirect_to bracket_path(token: @simulation.token),
                    notice: t("flash.prediction_saved", match_number: @match.match_number)
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_simulation
    @simulation = Simulation.find_by!(token: params[:token])
  end

  def load_match
    @match = Match.find_by!(match_number: params[:match_number], stage: "knockout")
  end

  def prediction_params
    params.require(:prediction).permit(:home_score, :away_score)
  end
end
