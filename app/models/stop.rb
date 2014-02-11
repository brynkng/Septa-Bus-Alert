class Stop < ActiveRecord::Base
  attr_accessible :latitude, :longitude, :stop_id, :stop_name, :route
end
