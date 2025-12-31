class Player < ApplicationRecord
  belongs_to :team

  scope :starters, -> { where(is_starter: true) }
  scope :substitutes, -> { where(is_starter: false) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def face_image_path
    return nil if fm_uid.blank?
    self.class.face_images_index[fm_uid]
  end

  # Build an index of fm_uid -> image path (cached at class level)
  def self.face_images_index
    @face_images_index ||= build_face_images_index
  end

  def self.build_face_images_index
    index = {}
    players_dir = Rails.root.join("app/assets/images/players")
    return index unless players_dir.exist?

    Dir.glob(players_dir.join("*.png")).each do |file|
      filename = File.basename(file)
      # Extract fm_uid from filename like "Albania_Adrion_Pajaziti_11020844.png"
      if filename =~ /(\d{6,})\.png$/
        uid = $1
        index[uid] = "players/#{filename}"
      end
    end
    index
  end

  def self.reload_face_images_index!
    @face_images_index = build_face_images_index
  end
end
