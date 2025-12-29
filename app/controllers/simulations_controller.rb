class SimulationsController < ApplicationController
  def start
    # 1) If the cookie is already there, we use it
    token = cookies.signed[:simulation_token]
    sim = token && Simulation.find_by(token: token)

    # 2) Otherwise, we create a new one
    unless sim
      sim = Simulation.create!(pseudo: "Invité")
      cookies.signed[:simulation_token] = {
        value: sim.token,
        expires: 6.months.from_now,
        httponly: true
      }
    end
    redirect_to simulation_path(sim.token)
  end

  def show
    @simulation = Simulation.find_by!(token: params[:token])
    # sécurité: si quelqu’un ouvre un lien /s/:token,
    # on "adopte" cette partie sur l’appareil (optionnel mais pratique)
    cookies.signed[:simulation_token] = {
      value: @simulation.token,
      expires: 6.months.from_now,
      httponly: true
    }
    @groups = Group.order(:name)
  end
end
