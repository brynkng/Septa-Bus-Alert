 #!/usr/bin/env ruby 

require 'pg'
require 'net/http'
require 'json'

def running!
  ActiveRecord::Base.connection.execute('UPDATE lock SET is_locked = true WHERE id = 1')
end

def done!
  ActiveRecord::Base.connection.execute('UPDATE lock SET is_locked = false WHERE id = 1')
end

def running?
  result = ActiveRecord::Base.connection.execute('SELECT is_locked FROM lock WHERE id = 1')
  return result.first['is_locked'] == 't'
end

task :gather => :environment do
  unless running?
    begin
      puts "Start gathering!"

      running!

      while true
        busNumbers = (1..206).to_a + ('G'..'R').to_a

        busNumbers.each do |busNum|
          puts "Processing bus: " + busNum.to_s

          uri = URI.parse("http://www3.septa.org/hackathon/TransitView/" + busNum.to_s)

          begin

            response = Net::HTTP.get_response(uri)

            if response.body != 'Invalid Route'
              response = JSON.parse response.body

              #response
              # ['bus'][array of buses][lat | lng | VehicleId | BlockId | Direction | destination | Offset]
              response['bus'].each do |bus|
                bus['route'] = busNum.to_s
                if bus['destination'] != ""
                  ActiveRecord::Base.connection.execute("INSERT INTO bus_history (route, latitute, longitude, vehicle_id, block_id, direction, destination, off_by) VALUES ('" \
                    + bus['route'] + "','" \
                    + bus['lat'] + "','" \
                    + bus['lng'] + "','" \
                    + bus['VehicleID'] + "','" \
                    + bus['BlockID'] + "','" \
                    + bus['Direction'] + "','" \
                    + bus['destination'] + "','" \
                    + bus['Offset'] + "')"
                  )
                end
              end
            end

          rescue Exception => e
            puts e
          end
        end

        puts "Sleeping..."
        sleep 5 * 60
      end
    ensure
      puts "Sad face :(. Gathering over"
      done!
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
#	latitute float,
#   longitude float,
#   vehicle_id integer,
#   block_id integer,
#   direction text,
#   destination text,
#   off_by integer
#);