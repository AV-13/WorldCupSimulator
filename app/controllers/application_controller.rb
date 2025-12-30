class ApplicationController < ActionController::Base
  before_action :set_locale

  private

  def set_locale
    locale = cookies.signed[:locale]&.to_sym
    I18n.locale = I18n.available_locales.include?(locale) ? locale : I18n.default_locale
  end

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
