module ApplicationHelper
  # Display a flag icon for a team
  # Uses flag-icons library (https://flagicons.lipis.dev/)
  def flag_icon(team, size: :normal)
    return "".html_safe unless team&.iso_code.present?

    style = case size
            when :small then "font-size: 16px;"
            when :large then "font-size: 48px;"
            else "font-size: 20px;"
            end

    tag.span(class: "fi fi-#{team.iso_code}", style: style)
  end
end
