class ApplicationController < ActionController::Base
  private

  def current_simulation
    return @current_simulation if defined?(@current_simulation)

    token = cookies.signed[:simulation_token]
    sim = token && Simulation.find_by(token: token)

    unless sim
      sim = Simulation.create!(pseudo: "Invité")
      cookies.signed[:simulation_token] = {
        value: sim.token,
        expires: 6.months.from_now,
        httponly: true
      }
    end

    @current_simulation = sim
  end
end
