class AddUniqueIndexOnPredictions < ActiveRecord::Migration[8.1]
  def change
    add_index :predictions, [ :simulation_id, :match_id ], unique: true
  end
end
