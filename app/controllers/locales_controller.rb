class LocalesController < ApplicationController
  def update
    locale = params[:locale]&.to_sym
    if I18n.available_locales.include?(locale)
      cookies.signed[:locale] = {
        value: locale,
        expires: 6.months.from_now,
        httponly: true
      }
    end
    redirect_back(fallback_location: root_path)
  end
end
