class Match < ApplicationRecord
  belongs_to :group, optional: true

  belongs_to :home_team, class_name: "Team", foreign_key: :home_team_id, optional: true
  belongs_to :away_team, class_name: "Team", foreign_key: :away_team_id, optional: true
end
