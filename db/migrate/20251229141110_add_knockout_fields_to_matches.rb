class AddKnockoutFieldsToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :round, :string
    add_column :matches, :match_number, :integer
    add_column :matches, :home_source, :string
    add_column :matches, :away_source, :string

    add_index :matches, :round
    add_index :matches, :match_number, unique: true
  end
end
