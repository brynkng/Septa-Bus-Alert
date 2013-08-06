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
    #find next bus (2)?
    closestBuses = []
    uri = URI.parse("http://www3.septa.org/hackathon/TransitView/" + route)

    begin

      response = Net::HTTP.get_response(uri)

      if response.body != 'Invalid Route'
        response = JSON.parse response.body

        #response
        # ['bus'][array of buses][lat | lng | VehicleId | BlockId | Direction | destination | Offset]
        response['bus'].each do |bus|
          currentBusDistance = abs(latitude - bus['lat']) + abs(longitude - bus['lng'])
          if (closestBuses.last.nil? or (currentBusDistance < closestBuses.last['distance']))
            closestBuses.push({:distance => currentBusDistance})
            closestBuses = closestBuses.pop! if closestBuses.length > 3
          end

        end

        sortedBuses = response['bus'].sort {
            |bus1, bus2|
          bus1Distance = abs(latitude - bus1['lat']) + abs(longitude - bus1['lng'])
          bus2Distance = abs(latitude - bus2['lat']) + abs(longitude - bus2['lng'])

          bus1Distance <=> bus2Distance
        }


      end
    end
  end



        #16832
        #{"lng":-75.16194,"lat":39.934726,"stopid":16832,"stopname":"11th St &amp; Federal St"}
    response = Net::HTTP.get_response()

    if response.body != 'Invalid Route'
      response = JSON.parse response.body
      response['bus'].each do |bus|

      end
    end
  end
end


#build a table of bus info