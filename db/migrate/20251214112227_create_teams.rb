class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :iso_code
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
