class NextArrival

	attr_reader :travel_time, :bus

	def initialize(travel_time, bus)
		@travel_time = travel_time
		@bus = bus
	end
end