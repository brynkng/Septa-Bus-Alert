require 'net/http'
require 'json'

class SeptaApiWrapper

	def self.get_next_buses_on_route(route_direction, desired_stop)
		route_short_name = route_direction.route_short_name
		direction = route_direction.direction_name
		latitude = desired_stop.stop_lat
		longitude = desired_stop.stop_lon
		uri = URI.parse("http://www3.septa.org/hackathon/TransitView/" + route_short_name)

		begin

			response = Net::HTTP.get_response(uri)

			if response.body != 'Invalid Route'
				response = JSON.parse response.body
				response['bus'].keep_if {
						|bus|

					if bus['Direction'].downcase == direction.downcase
						case direction.downcase
							when 'northbound'
								bus['lat'].to_f < latitude
							when 'southbound'
								bus['lat'].to_f > latitude
							when 'westbound'
								bus['long'].to_f < longitude
							when 'eastbound'
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

				septaBuses = []

				sortedBuses.map {|bus| septaBuses.push(::SeptaBus.new(bus['lat'], bus['lng'], bus['VehicleID'], bus['Direction'], bus['destination'], bus['Offset']))}

				#sortedBuses.each do |bus|
				#	puts bus.inspect
				#end

				septaBuses
			end
		end
	end
end