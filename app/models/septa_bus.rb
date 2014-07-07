class SeptaBus

	attr_accessor :latitude, :longitude, :vehicle_id, :direction, :destination, :offset

	def initialize(latitude, longitude, vehicle_id, direction, destination, offset)
		@latitude = latitude
		@longitude = longitude
		@vehicle_id = vehicle_id
		@direction = direction
		@destination = destination
		@offset = offset
	end
end