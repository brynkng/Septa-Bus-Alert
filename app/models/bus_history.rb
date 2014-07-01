class BusHistory < ActiveRecord::Base
  set_table_name :bus_history
  reverse_geocoded_by :latitude, :longitude
end
