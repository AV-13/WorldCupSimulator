class Match < ApplicationRecord
  belongs_to :group, optional: true

  belongs_to :home_team, class_name: "Team", foreign_key: :home_team_id, optional: true
  belongs_to :away_team, class_name: "Team", foreign_key: :away_team_id, optional: true

  # Scopes
  scope :group_stage, -> { where(stage: "group_stage") }
  scope :knockout, -> { where(stage: "knockout") }
  scope :round_of_32, -> { knockout.where(round: "round_of_32") }
  scope :round_of_16, -> { knockout.where(round: "round_of_16") }
  scope :quarter_finals, -> { knockout.where(round: "quarter_final") }
  scope :semi_finals, -> { knockout.where(round: "semi_final") }
  scope :third_place_match, -> { knockout.where(round: "third_place") }
  scope :final_match, -> { knockout.where(round: "final") }

  # Round display names
  ROUND_NAMES = {
    "group_stage" => "Phase de groupes",
    "round_of_32" => "Huitièmes de finale",
    "round_of_16" => "Quarts de finale",
    "quarter_final" => "Quarts de finale",
    "semi_final" => "Demi-finales",
    "third_place" => "Match pour la 3ème place",
    "final" => "Finale"
  }.freeze

  def round_name
    ROUND_NAMES[round] || round&.titleize
  end

  def knockout?
    stage == "knockout"
  end

  def group_stage?
    stage == "group_stage"
  end

  # Check if both teams are determined
  def teams_known?
    home_team.present? && away_team.present?
  end
end
