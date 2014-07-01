class MigrateToUseGtfs < ActiveRecord::Migration
  def up

    #add routes
    create_table :routes do |t|
      t.string "route_id"
      t.string "route_short_name"
      t.string "route_long_name"
      t.string "route_desc"
      t.string "agency_id"
      t.integer "route_type"
      t.string "route_color", :limit => 6
      t.string "route_text_color", :limit => 6
      t.string "route_url"
      t.timestamps
    end
    add_index :routes, :route_id

    #add stops
    create_table :stops do |t|
      t.integer "stop_id"
      t.string "stop_name"
      t.decimal "stop_lat"
      t.decimal "stop_lon"
      t.string "location_type"
      t.integer "parent_station"
      t.integer "zone_id"
      t.timestamps
    end
    add_index :stops, :stop_id

    #add simplified stops
    create_table :simplified_stops do |t|
      t.string "route_id"
      t.integer "route_direction_id"
      t.integer "direction_id"
      t.integer "stop_id"
      t.string "stop_name"
      t.integer "stop_sequence"
      t.decimal "stop_lat"
      t.decimal "stop_lon"
      t.timestamps
    end
    add_index :simplified_stops, :route_direction_id
    add_index :simplified_stops, :stop_id

    #add route directions
    create_table :route_directions do |t|
      t.string "route_id"
      t.string "route_short_name"
      t.integer "direction_id"
      t.string "direction_name"
      t.string "direction_long_name"
      t.timestamps
    end
    add_index :route_directions, :route_id
    add_index :route_directions, :route_short_name
  end

  def down
  end
end
