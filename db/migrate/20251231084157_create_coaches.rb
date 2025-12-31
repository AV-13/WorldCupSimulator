class CreateCoaches < ActiveRecord::Migration[8.1]
  def change
    create_table :coaches do |t|
      t.references :team, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
