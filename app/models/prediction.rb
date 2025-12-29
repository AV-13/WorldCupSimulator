class Prediction < ApplicationRecord
  belongs_to :simulation
  belongs_to :match

  validates :home_score, :away_score, numericality: { only_integer: true, allow_nil: true }
  validates :match_id, uniqueness: { scope: :simulation_id }
end
