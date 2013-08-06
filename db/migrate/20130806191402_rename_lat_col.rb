class RenameLatCol < ActiveRecord::Migration
  def up
    rename_column :bus_history, :latitute, :latitude
  end

  def down
  end
end
