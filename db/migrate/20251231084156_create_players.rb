class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.references :team, null: false, foreign_key: true
      t.string :fm_uid
      t.string :fotmob_id
      t.string :first_name
      t.string :last_name
      t.string :position
      t.integer :jersey_number
      t.date :birth_date
      t.string :club
      t.boolean :is_starter
      t.integer :grid_row
      t.integer :grid_col

      t.timestamps
    end
  end
end
