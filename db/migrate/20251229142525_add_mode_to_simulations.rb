class AddModeToSimulations < ActiveRecord::Migration[8.1]
  def change
    add_column :simulations, :mode, :string, default: "complete", null: false
    add_index :simulations, :mode
  end
end
