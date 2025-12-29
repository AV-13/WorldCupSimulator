class Group < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :matches, dependent: :destroy
end
