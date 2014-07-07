require 'json'

#examples

#broad and chestnut, route 4
#estimate/23/NorthBound/15185

#federal and 11th stop
#estimate/23/NorthBound/16832

class EstimatorController < ActionController::Base
	protect_from_forgery

	def estimate
		route_short_name = params[:route]
		direction = params[:direction]
		stop_id = params[:stop_id]
		route_direction = RouteDirection.find_by_route_short_name_and_direction_name(route_short_name, direction)

		desiredStop = SimplifiedStop.where('stop_id = ? AND route_direction_id = ?', stop_id, route_direction.id).first

		unless desiredStop
			render json: 'Invalid stop id or route'
			return
		end

		next_arrival = ::TravelTimeCalculator.get_next_arrival(route_direction, desiredStop)

		render json: {travel_time: Time.at(next_arrival.travel_time).utc.strftime("%H:%M:%S"), bus: next_arrival.bus.vehicle_id}

	end
end