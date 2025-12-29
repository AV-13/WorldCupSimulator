class Simulation < ApplicationRecord
  has_many :predictions, dependent: :destroy

  # Modes disponibles
  MODES = {
    "complete" => "Simulation complete (entrer tous les scores)",
    "quick" => "Simulation rapide (classer les equipes)"
  }.freeze

  validates :mode, inclusion: { in: MODES.keys }

  before_create :generate_token

  def complete_mode?
    mode == "complete"
  end

  def quick_mode?
    mode == "quick"
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
