class AddStops < ActiveRecord::Migration
  def change
    require 'net/http'
    require 'json'

      routes = ActiveRecord::Base.connection.execute("SELECT DISTINCT route FROM bus_history").to_a.map {|routeHash| routeHash['route']}

      routes.each do |route|
        uri = URI.parse("http://www3.septa.org/hackathon/Stops/" + route)
        puts 'processing route: ' + route

        response = Net::HTTP.get_response(uri)
        if response.body.length > 0
          response = JSON.parse response.body
          response.each do |stop|
            puts '    processing stop: ' + stop['stopid'].to_s
            Stop.create!(latitude: stop['lat'], longitude: stop['lng'], stop_id: stop['stopid'], stop_name: stop['stopname'], route: route)
          end
        end
      end

  end
end
