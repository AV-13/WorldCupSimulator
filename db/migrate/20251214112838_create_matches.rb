class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.string :stage
      t.references :group, null: true, foreign_key: true
      t.references :home_team, null: true, foreign_key: { to_table: :teams }
      t.references :away_team, null: true, foreign_key: { to_table: :teams }

      t.timestamps
    end
  end
end