require 'json'

#examples

#broad and chestnut, route 4
#estimate/23/NorthBound/15185

#federal and 11th stop
#estimate/23/NorthBound/16832

class EstimatorController < ActionController::Base
  protect_from_forgery

  def estimate()
    route = params[:route]
    direction = params[:direction]
    stop_id = params[:stop_id]
	stop = Stop.find_by_stop_id(stop_id)

	unless stop
		render :json => 'Invalid stop id for route'
		return
	end

	latitude = stop.stop_lat
	longitude = stop.stop_lon

    buses = ::SeptaApiWrapper.get_next_buses_on_route(route, direction, latitude, longitude)

	render :json => buses
	return



        #render :json => {
        #    'time to arrive' => finalArrivalData[:time_to_arrive].to_s + ' minutes',
        #    'vehicle' => nextToArrive['VehicleID'],
        #    'm/s' => finalArrivalData[:meters_per_sec],
        #    'distance' => finalArrivalData[:distance],
        #    'start' => nextToArrive['lat'].to_s + ', ' + nextToArrive['lng'],
        #    'end' => @latitude.to_s + ', ' + @longitude.to_s
        #}
        #return
  end
end