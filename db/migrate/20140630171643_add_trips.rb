class AddTrips < ActiveRecord::Migration
  def up
    create_table :trips do |t|
      t.integer "route_id"
      t.string "service_id"
      t.string "trip_id"
      t.string "trip_headsign"
      t.integer "block_id"
      t.integer "direction_id"
      t.string "trip_short_name"
      t.string "shape_id"
      t.timestamps
    end
    add_index :trips, :route_id
    add_index :trips, :trip_id

    create_table :stop_times do |t|
      t.string "trip_id"
      t.string "arrival_time"
      t.string "departure_time"
      t.integer "stop_id"
      t.integer "stop_sequence"
      t.integer "pickup_type"
      t.integer "drop_off_type"
      t.timestamps
    end
    add_index :stop_times, :trip_id
    add_index :stop_times, :stop_id

    create_table :trip_variants do |t|
      t.integer :route_id
      t.integer :direction_id
      t.string :trip_headsign
      t.integer :stop_count
      t.string :variant_name
      t.integer :first_stop_sequence
      t.integer :last_stop_sequence

      t.timestamps
    end

    add_column :trips, :trip_variant_id, :integer

    change_column :trip_variants, :route_id, :string
  end

  def down
  end
end
