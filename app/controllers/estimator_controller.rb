require 'json'

#examples

#broad and chestnut, route 4
#estimate/23/NorthBound/15185

#federal and 11th stop
#estimate/23/NorthBound/16832

class EstimatorController < ActionController::Base
	protect_from_forgery

	def estimate

		desired_stop = get_desired_stop

		if desired_stop.nil?
			render json: 'Invalid stop id or route'
			return
		end

		next_arrival = ::TravelTimeCalculator.get_next_arrival(desired_stop)

		render json: {arrival_time: Time.at(Time.now + next_arrival.travel_time.to_i.seconds).strftime("%I:%M:%S"), travel_time: Time.at(next_arrival.travel_time).utc.strftime("%M:%S"), bus: next_arrival.bus.vehicle_id}

	end

	def estimate_all
		desired_stop = get_desired_stop

		if desired_stop.nil?
			render json: 'Invalid stop id or route'
			return
		end

		next_arrivals = ::TravelTimeCalculator.get_next_arrivals_for_all_buses(desired_stop)

		#next_arrivals.each do |arrival|
		#
		#end

		render json: next_arrivals

	end


	private

	def get_desired_stop
		route_short_name = params[:route]
		direction = params[:direction]
		stop_id = params[:stop_id]
		route_direction = RouteDirection.find_by_route_short_name_and_direction_name(route_short_name, direction)

		return SimplifiedStop.where('stop_id = ? AND route_direction_id = ?', stop_id, route_direction.id).first
	end
end