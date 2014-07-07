class TravelTimeCalculator

	def self.get_next_arrivals_for_all_buses(desired_stop)
		next_arrivals = []
		route_direction = RouteDirection.find_by_id(desired_stop.route_direction_id)
		first_direction_buses = ::SeptaApiWrapper.get_next_buses_on_route(route_direction, desired_stop)

		first_direction_buses.each do |bus|
			travel_time = find_travel_time_between_bus_and_stop(bus, desired_stop)
			next_arrivals.push(::NextArrival.new(travel_time, bus))
		end

		opposite_route_direction = get_opposite_direction(route_direction)
		last_stop_opposite_direction = get_last_stop_on_route(opposite_route_direction)
		first_stop_first_direction = get_first_stop_on_route(route_direction)
		opposite_direction_buses = ::SeptaApiWrapper.get_next_buses_on_route(opposite_route_direction, last_stop_opposite_direction)

		opposite_direction_buses.each do |bus|
			travel_time_opposite = find_travel_time_between_bus_and_stop(bus, last_stop_opposite_direction)
			travel_time_first = get_travel_time_between_stops(first_stop_first_direction, desired_stop)
			next_arrivals.push(::NextArrival.new(travel_time_opposite + travel_time_first, bus))
		end

		return next_arrivals
	end

	def self.get_next_arrival(desired_stop)

		route_direction = RouteDirection.find_by_id(desired_stop.route_direction_id)
		travel_time = nil
		bus = nil

		travel_time, bus = calculate_travel_time_until_next_bus(route_direction, desired_stop)

		unless travel_time > 0
			#most likely we couldn't find any more buses going this direction, let's find the furthest one along the opposite direction
			#puts 'Searching buses in opposite direction'

			opposite_route_direction = get_opposite_direction(route_direction)

			last_stop_on_opposite_direction = get_last_stop_on_route(opposite_route_direction)
			first_stop_on_route = get_first_stop_on_route(route_direction)

			opposite_route_travel_time, bus = self.calculate_travel_time_until_next_bus(opposite_route_direction, last_stop_on_opposite_direction)
			#puts 'opposite route travel time: ' + opposite_route_travel_time.to_s
			#puts "\n"

			first_stop_travel_time = self.get_travel_time_between_stops(first_stop_on_route, desired_stop)
			#puts 'travel time from first stop: ' + first_stop_travel_time.to_s

			travel_time = opposite_route_travel_time + first_stop_travel_time
		end

		return ::NextArrival.new(travel_time, bus)
	end


	private

	def self.get_opposite_direction(route_direction)
		RouteDirection.where(
				'route_id = ? and direction_id = ?',
				route_direction.route_id,
				route_direction.direction_id == 0 ? 1 : 0
		).first
	end

	def self.get_first_stop_on_route(route_direction)
		SimplifiedStop.where('route_direction_id = ?', route_direction.id).order('stop_sequence').limit(1).first
	end

	def self.get_last_stop_on_route(route_direction)
		#skip the very last one because we repeat the data repeats the same stop for the last and first of a direction. This way we only count it once
		SimplifiedStop.where('route_direction_id = ?', route_direction.id).order('stop_sequence DESC').limit(2)[1]
	end

	def self.calculate_travel_time_until_next_bus(route_direction, desired_stop)
		buses = ::SeptaApiWrapper.get_next_buses_on_route(route_direction, desired_stop)
		puts buses.inspect
		travel_time = 0
		bus_number = 0
		bus = nil

		while travel_time < 1 and bus_number < buses.count
			bus = buses[bus_number]

			travel_time = find_travel_time_between_bus_and_stop(bus, desired_stop)

			bus_number += 1
		end

		return travel_time, bus
	end

	def self.find_travel_time_between_bus_and_stop(bus, desired_stop)
		route_direction = RouteDirection.find_by_id(desired_stop.route_direction_id)

		stop_near_bus = find_closest_stop_to_bus(route_direction, bus)

		abort("Couldn't find stop near bus") unless stop_near_bus

		#puts 'stop near bus: ' + stop_near_bus.stop_id.to_s
		travel_time_between_stops = get_travel_time_between_stops(stop_near_bus, desired_stop)
		#puts 'travel time between stops: ' + travel_time_between_stops.to_s
		offset = (bus.offset.to_i * 60)
		#puts 'offset: ' + offset.to_s

		return travel_time_between_stops - offset
	end

	def self.find_closest_stop_to_bus(route_direction, bus)
		SimplifiedStop.near([bus.latitude, bus.longitude])
		.where('route_direction_id = ?',route_direction.id)
		.order(:distance).first
	end

	def self.get_travel_time_between_stops(start_stop, end_stop)
		travel_time = 0
		#puts 'start stop: ' + start_stop.stop_id.to_s
		#puts 'end stop: ' + end_stop.stop_id.to_s

		stop_slots = get_stop_slots_between_stops(start_stop, end_stop)

		#stop_slots.each do |slot|
		#	puts 'stop slot distance time: ' + slot.distance_time.to_s
		#	puts 'stop slot stop id: ' + slot.stop_id.to_s
		#	puts "\n"
		#end

		stop_slot_times = stop_slots.map{|slot| slot.distance_time}

		unless stop_slot_times.empty?
			mean = stop_slot_times[(stop_slot_times.count / 2).to_i]
			if stop_slot_times.count > 4
				outlier_limit = 1.5 * interquartile_mean(stop_slot_times).to_i
			else
				outlier_limit = 1.5 * mean
			end

			#puts 'outlier limit: ' + outlier_limit.to_s
			#
			#stop_slot_times.each do |time|
			#	puts 'time: ' + time.to_s
			#end

			#this seems like a stupid hack, we should prevent skewed slots from being recorded in the first place
			stop_slot_times.each do |time|
				if time > outlier_limit
					travel_time += mean
				else
					travel_time += time
				end
			end
		end

		#travel_time = 0
		#stop_slots.each do |stop_slot|
		#	p stop_slot
		#	travel_time += stop_slot.distance_time
		#end

		return travel_time
	end

	#
	# Params:
	# +start_stop+:: +SimplifiedStop+ object
	# +end_stop+:: +SimplifiedStop+ object
	def self.get_stop_slots_between_stops(start_stop, end_stop)
		stop_ids = SimplifiedStop.where(
				'route_id = ? AND route_direction_id = ? AND stop_sequence BETWEEN ? AND ?',
				start_stop.route_id,
				start_stop.route_direction_id,
				start_stop.stop_sequence,
				end_stop.stop_sequence
		).map{|stop| stop.stop_id}

		stop_slots = nil
		current_hour = Time.now.strftime('%H').to_i
		times_looped = 1

		while stop_slots.nil? and times_looped < 12

			#puts 'is weekend? ' + is_weekend?.to_s
			#puts 'current time slot: ' + get_current_time_slot(current_hour).to_s
			#puts 'stop ids: ' + stop_ids.to_s

			stop_slots = StopSlot.where(
					'stop_id IN (?) AND is_weekend = ? AND time_slot = ?',
					stop_ids,
					is_weekend?,
					get_current_time_slot(current_hour)
			)

			current_hour += 2
			current_hour = 0 if current_hour == 24
			times_looped += 1
		end

		stop_slots = [] if stop_slots.nil?

		return stop_slots
	end

	def self.is_weekend?
		!!(Date.today.saturday? or Date.today.sunday?)
	end

	def self.get_current_time_slot(current_hour)

		current_hour = (current_hour - 1) if current_hour.odd?

		return current_hour
	end

	def self.interquartile_mean(array)
		arr = array.sort
		length = arr.size
		quart = (length/4.0).floor
		fraction = 1-((length/4.0)-quart)
		new_arr = arr[quart..-(quart + 1)]
		(fraction*(new_arr[0]+new_arr[-1]) + new_arr[1..-2].inject(:+))/(length/2.0)
	end

end