 #!/usr/bin/env ruby 

require 'pg'
require 'net/http'
require 'json'

# def running!
#   ActiveRecord::Base.connection.execute('UPDATE lock SET is_locked = true WHERE id = 1')
# end

# def done!
#   ActiveRecord::Base.connection.execute('UPDATE lock SET is_locked = false WHERE id = 1')
# end

def running?
  #result = ActiveRecord::Base.connection.execute('SELECT time FROM bus_history ORDER BY time DESC LIMIT 1')
  #if result.first.nil?
  #  return false
  #end
  #minutesSinceLastRun = (((Time.now.to_i - DateTime.parse(result.first['time']).to_i).abs)/60).round
  #return minutesSinceLastRun < 5

  pidLocation = "/tmp/gather.pid"

   File.exists?(pidLocation)
end

task :gather => :environment do
  pidLocation = "/tmp/gather.pid"
  unless running?
    begin
      puts "Start gathering!"
      File.open(pidLocation, 'w') {
        |file| file.write("Running")
      }

      while true

          uri = URI.parse("http://www3.septa.org/hackathon/TransitViewAll/")

          begin

            response = Net::HTTP.get_response(uri)

            if response.body.length > 0
              response = JSON.parse response.body
              #response
              #{"date time"=>[{"route"=>[{"lat"=>40.005753, "lng"=>-75.194183, "label"=>8188, "VehicleID"=>8188, "BlockID"=>1013, "Direction"=>" ", "destination"=>nil, "Offset"=>1}]}]}
              response[response.keys.first].each do |routeData|
                route = routeData.keys.first

                puts "Processing route: " + route.to_s

                routeData[route].each do |bus|

                  if bus['destination'].to_s != "" and bus['Offset'].to_i == 0 and bus['Direction'].to_s != ' '
                    ActiveRecord::Base.connection.execute("INSERT INTO bus_history (route, latitude, longitude, vehicle_id, block_id, direction, destination, off_by) VALUES ('" \
                      + route + "','" \
                      + bus['lat'].to_s + "','" \
                      + bus['lng'].to_s + "','" \
                      + bus['VehicleID'].to_s + "','" \
                      + bus['BlockID'].to_s + "','" \
                      + bus['Direction'] + "','" \
                      + bus['destination'] + "','" \
                      + bus['Offset'].to_s + "')"
                    )
                  end
                end
              end
            end

          rescue Exception => e
            puts e
          end

        #free up resources and run GC
        uri = nil
        response = nil

        GC.start

        puts "Sleeping..."
        sleep 5 * 60
      end
    ensure
      puts "Sad face :(. Gathering over"
      File.delete(pidLocation) if running?
    end
  end
end

#find out general bus times and only grab data during those times so as to not waste space

# find average (last 3 weeks?) of the recorded time from point a to point b at same day of week and time of day. cached locally - updated every week?
# each lookup will be a combination of current time and location + the average history of previous amount of time to take to get to destination. 
# each lookup should take detours into account

#use color scheme 

#probably need to use google maps api to get current walking time between two points.






# conn.exec( "SELECT * FROM pg_stat_activity" ) do |result| 
# 	puts " PID | User | Query" 
# 	result.each do |row| 
# 		puts " %7d | %-16s | %s " % row.values_at('procpid', 'usename', 'current_query') 
# 	end 
# end

#CREATE TABLE bus_history (
#	id serial,
#	time timestamp default NOW(),
#	route text,
#	latitude float,
#   longitude float,
#   vehicle_id integer,
#   block_id integer,
#   direction text,
#   destination text,
#   off_by integer
#);