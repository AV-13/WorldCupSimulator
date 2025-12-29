class Simulation < ApplicationRecord
  has_many :predictions, dependent: :destroy

  before_create :generate_token

  private
  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
