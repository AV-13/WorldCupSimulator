class Coach < ApplicationRecord
  belongs_to :team

  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns face image path if fm_uid column exists and image is found
  def face_image_path
    return nil unless respond_to?(:fm_uid) && fm_uid.present?
    self.class.face_images_index[fm_uid]
  end

  # Build an index of fm_uid -> image path (cached at class level)
  def self.face_images_index
    @face_images_index ||= build_face_images_index
  end

  def self.build_face_images_index
    index = {}
    coaches_dir = Rails.root.join("app/assets/images/coach")
    return index unless coaches_dir.exist?

    Dir.glob(coaches_dir.join("*.png")).each do |file|
      filename = File.basename(file)
      # Format: Country_FirstName_LastName_fmuid.png (e.g., Argentina_Lionel_Scaloni_2000219.png)
      if filename =~ /_(\d+)\.png$/
        uid = $1
        index[uid] = "coach/#{filename}"
      end
    end
    index
  end

  def self.reload_face_images_index!
    @face_images_index = build_face_images_index
  end
end
