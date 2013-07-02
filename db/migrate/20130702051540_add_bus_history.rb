class AddBusHistory < ActiveRecord::Migration
  def up
    sql = "CREATE TABLE bus_history (
	id serial,
	time timestamp default NOW(),
	route text,
	latitute float,
   longitude float,
   vehicle_id integer,
   block_id integer,
   direction text,
   destination text,
   off_by integer
);"
    ActiveRecord::Base.connection.execute(sql)

  end

  def down
  end
end
