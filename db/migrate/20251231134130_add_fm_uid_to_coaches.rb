class AddFmUidToCoaches < ActiveRecord::Migration[8.1]
  def change
    add_column :coaches, :fm_uid, :string
  end
end
