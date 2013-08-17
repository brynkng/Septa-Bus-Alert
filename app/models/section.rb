class Section < ActiveRecord::Base
  attr_accessible :direction, :end_latitude, :end_longitude, :is_weekday, :route, :speed, :start_hour, :start_latitude, :start_longitude
end
