class AddBusHistoryIndeces < ActiveRecord::Migration
  def up
    add_index :bus_history, [:route, :direction, :time, :latitude, :longitude], name: 'route direction'
  end

  def down
  end
end
