class Team < ApplicationRecord
  belongs_to :group

  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :nullify
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :nullify
  has_many :players, dependent: :destroy
  has_one :coach, dependent: :destroy
end
