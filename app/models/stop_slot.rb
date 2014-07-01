class StopSlot < ActiveRecord::Base
  attr_accessible :direction, :is_weekend, :route_id, :stop_id, :distance_time, :time_slot
end
