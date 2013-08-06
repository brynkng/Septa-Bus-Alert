require 'net/http'
require 'json'

class EstimatorController < ActionController::Base
  protect_from_forgery

  def estimate
    #latitude = params[:latitude]
    #longitude = params[:longitude]
    #route = params[:route]
    #direction = params[:direction]

    route = 23
    longitude = -75.16194
    latitude = 39.934726
    direction = "NorthBound"

    buses = getNextBusesToArrive(direction, latitude, longitude, route)

    #ActiveRecord::Base.connection.execute("
    #SELECT
    #  vehicle_id, time
    #FROM bus_history
    #WHERE
    #  route = '23'
    #  and latitude::text like '40.077%'
    #  and longitude::text like '-75.161%'
    #  and time::text like '% 16:%';
    #")

    render :json => buses.first
  end

  def getNextBusesToArrive(direction, latitude, longitude, route)
    uri = URI.parse("http://www3.septa.org/hackathon/TransitView/" + route.to_s)

    begin

      response = Net::HTTP.get_response(uri)

      if response.body != 'Invalid Route'
        response = JSON.parse response.body
        response['bus'].keep_if {
            |bus|

          if bus['Direction'] == direction
            case direction
              when 'NorthBound'
                bus['lat'].to_f < latitude
              when 'SouthBound'
                bus['lat'].to_f > latitude
              when 'WestBound'
                bus['long'].to_f < longitude
              when 'EastBound'
                bus['long'].to_f > longitude
            end
          end
        }

        #response
        # ['bus'][array of buses][lat | lng | VehicleID | BlockId | Direction | destination | Offset]

        sortedBuses = response['bus'].sort {
            |bus1, bus2|
          bus1Distance = (latitude - bus1['lat'].to_f).abs + (longitude - bus1['lng'].to_f).abs
          bus2Distance = (latitude - bus2['lat'].to_f).abs + (longitude - bus2['lng'].to_f).abs
          bus1Distance <=> bus2Distance
        }

        return sortedBuses
      end
    end
  end
end


#build a table of bus info