class CreateStopSlots < ActiveRecord::Migration
  def change
    create_table :stop_slots do |t|
      t.string :route_id
      t.string :direction
      t.integer :stop_id
      t.boolean :is_weekend
      t.integer :time_slot
      t.integer :distance_time

      t.timestamps
    end
  end
end
