class AddScoresToPredictions < ActiveRecord::Migration[8.1]
  def change
    add_column :predictions, :home_score, :integer
    add_column :predictions, :away_score, :integer
  end
end
