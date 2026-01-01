module ApplicationHelper
  # Map locale codes to flag-icons country codes
  LOCALE_FLAGS = {
    fr: "fr",
    en: "gb",
    es: "es",
    pt: "pt",
    de: "de"
  }.freeze

  # Get flag code for a locale
  def locale_flag(locale)
    LOCALE_FLAGS[locale.to_sym] || "un"
  end

  # Display a flag icon for a team
  # Uses flag-icons library (https://flagicons.lipis.dev/)
  def flag_icon(team, size: :normal)
    return "".html_safe unless team&.iso_code.present?

    css_class = "fi fi-#{team.iso_code}"
    css_class += " fi-large" if size == :large

    tag.span(class: css_class)
  end

  # Bracket tree helpers
  def bracket_team_classes(team, winner, match, prediction, quick_mode)
    has_winner = prediction&.home_score && prediction&.away_score
    is_winner = team && winner == team
    can_click = quick_mode && match.teams_known? && !has_winner

    classes = [ "bracket-tree-team" ]
    classes << "winner" if is_winner
    classes << "clickable" if can_click
    classes << "tbd" unless team
    classes.join(" ")
  end

  def bracket_match_winner(match, prediction)
    return nil unless prediction&.home_score && prediction&.away_score
    prediction.home_score > prediction.away_score ? match.home_team : match.away_team
  end

  def bracket_can_click?(match, prediction, quick_mode)
    has_winner = prediction&.home_score && prediction&.away_score
    quick_mode && match.teams_known? && !has_winner
  end

  # Display player face image with fallback to placeholder
  def player_face_image(player, alt:, css_class: nil)
    face_path = player[:face_image]

    if face_path && Rails.application.assets&.load_path&.find(face_path)
      image_tag face_path, alt: alt, class: css_class
    else
      image_tag "player_placeholder.jpg", alt: alt, class: css_class
    end
  end

  # Lineup icon button - displays a tactical pitch icon linking to team lineup
  def lineup_icon(team, simulation, match: nil)
    return "".html_safe unless team

    path = match ? team_lineup_path(simulation.token, team, match_id: match.id) : team_lineup_path(simulation.token, team)

    link_to path, class: "lineup-icon-btn", title: t("lineup.view", default: "View lineup") do
      tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        width: 14,
        height: 14,
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        "stroke-width": 2,
        "stroke-linecap": "round",
        "stroke-linejoin": "round"
      ) do
        safe_join([
          tag.rect(x: 2, y: 3, width: 20, height: 18, rx: 2),
          tag.line(x1: 2, y1: 12, x2: 22, y2: 12),
          tag.circle(cx: 12, cy: 12, r: 3),
          tag.circle(cx: 6, cy: 7, r: 1.5),
          tag.circle(cx: 18, cy: 7, r: 1.5),
          tag.circle(cx: 6, cy: 17, r: 1.5),
          tag.circle(cx: 18, cy: 17, r: 1.5),
          tag.circle(cx: 12, cy: 7, r: 1.5),
          tag.circle(cx: 12, cy: 17, r: 1.5)
        ])
      end
    end
  end

  # Page title bar - simple centered title
  def page_title_bar(title, highlight: nil)
    tag.div(class: "page-title-bar") do
      tag.h1(class: "page-title") do
        if highlight
          safe_join([ title.upcase, " ", tag.span(highlight.upcase) ])
        else
          title.upcase
        end
      end
    end
  end

  # Back link with SVG arrow icon
  def back_link(path, text)
    link_to path, class: "back-link" do
      safe_join([
        tag.span(class: "back-link-icon") do
          tag.svg(
            xmlns: "http://www.w3.org/2000/svg",
            width: 20,
            height: 20,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            "stroke-width": 2.5,
            "stroke-linecap": "round",
            "stroke-linejoin": "round"
          ) do
            safe_join([
              tag.path(d: "M19 12H5"),
              tag.polyline(points: "12 19 5 12 12 5")
            ])
          end
        end,
        tag.span(text, class: "back-link-text")
      ])
    end
  end

  # Team info link - displays team name as clickable link with info icon
  def team_info_link(team)
    return "".html_safe unless team

    tag.span(class: "team-info-link") do
      safe_join([
        link_to(team.name, teams_path(team_id: team.id), class: "team-name-link"),
        link_to(teams_path(team_id: team.id), class: "team-info-icon", title: t("teams.view_details", default: "View team details")) do
          tag.svg(
            xmlns: "http://www.w3.org/2000/svg",
            width: 14,
            height: 14,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            "stroke-width": 2,
            "stroke-linecap": "round",
            "stroke-linejoin": "round"
          ) do
            safe_join([
              tag.circle(cx: 12, cy: 12, r: 10),
              tag.line(x1: 12, y1: 16, x2: 12, y2: 12),
              tag.line(x1: 12, y1: 8, x2: 12.01, y2: 8)
            ])
          end
        end
      ])
    end
  end
end
