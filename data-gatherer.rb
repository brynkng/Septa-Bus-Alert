 #!/usr/bin/env ruby 

require 'pg'
require 'net/http'
require 'json'

conn = PG.connect( dbname: 'septa_bus_alert' ) 

uri = URI.parse("http://www3.septa.org/hackathon/TransitView/17")

response = Net::HTTP.get_response(uri)
puts response.body	

#find out general bus times and only grab data during those times so as to not waste space

# find average (last 3 weeks?) of the recorded time from point a to point b at same day of week and time of day. cached locally - updated every week?
# each lookup will be a combination of current time and location + the average history of previous amount of time to take to get to destination. 
# each lookup should take detours into account

#probably need to use google maps api to get current walking time between two points.

# conn.exec( "SELECT * FROM pg_stat_activity" ) do |result| 
# 	puts " PID | User | Query" 
# 	result.each do |row| 
# 		puts " %7d | %-16s | %s " % row.values_at('procpid', 'usename', 'current_query') 
# 	end 
# end

# CREATE TABLE bus_history (
#	id integer auto_increment,
# 	time timestamp,
# 	latitute float,
#   longitude float,
#   vehicle_id integer,
#   block_id integer,
#   direction string,
#   destination string,
#   offset integer
# )