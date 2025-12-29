module ApplicationHelper
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

    classes = ['bracket-tree-team']
    classes << 'winner' if is_winner
    classes << 'clickable' if can_click
    classes << 'tbd' unless team
    classes.join(' ')
  end

  def bracket_match_winner(match, prediction)
    return nil unless prediction&.home_score && prediction&.away_score
    prediction.home_score > prediction.away_score ? match.home_team : match.away_team
  end

  def bracket_can_click?(match, prediction, quick_mode)
    has_winner = prediction&.home_score && prediction&.away_score
    quick_mode && match.teams_known? && !has_winner
  end
end
