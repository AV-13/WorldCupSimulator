class AddTokenToSimulations < ActiveRecord::Migration[8.1]
  def change
    add_column :simulations, :token, :string
    add_index :simulations, :token, unique: true
  end
end
