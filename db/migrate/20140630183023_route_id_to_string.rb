class RouteIdToString < ActiveRecord::Migration
  def up
    change_column :trips, :route_id, :string
    change_column :trip_variants, :route_id, :string
  end

  def down
  end
end
