require 'net/http'
require 'json'

class SeptaApiWrapper

	def self.get_next_buses_on_route(route, direction, latitude, longitude)
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