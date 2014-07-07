task :import_stop_slots , [:route] => :environment do |t, args|
  args.with_defaults(:route => "all")

  puts "Starting import for: " + args.route

  if args.route == 'all'
    routes = RouteDirection.all
	StopSlot.destroy_all
  else
    routes = RouteDirection.find_all_by_route_short_name_and_direction_name(args.route, 'Northbound')
	StopSlot.destroy_all(route_id: routes.first.route_id)
  end

  hourInterval = 2

  routes.each do |route|
    next if route.route_short_name == '1' or route.route_short_name == '10'

    direction = route.direction_name.sub 'bound', 'Bound'
    stops = SimplifiedStop.joins('INNER JOIN route_directions rd ON simplified_stops.route_direction_id = rd.id').where('rd.route_id = ? AND direction_name = ?', route.route_id, route.direction_name).order('stop_sequence')

    stops.each_slice(2) do |startStop, endStop|

      next if endStop.nil? or startStop.stop_id == endStop.stop_id
      puts "\n"
      puts '-----------------------------------'
      puts 'route: ' + route.route_short_name
      puts 'direction: ' + direction
      #puts 'lat: ' + startStop.stop_lat.to_s
      #puts 'lon: ' + startStop.stop_lon.to_s
      #puts 'start stop id: ' + startStop.stop_id.to_s
      #puts 'end stop id: ' + endStop.stop_id.to_s

      #group into weekend/time intervals

      isWeekendSwitch = [true, false]
      isWeekendSwitch.each do |isWeekend|
        #puts "is weekend?: " + isWeekend.to_s

        startTime = 0
        while startTime <= 23
          #puts 'time slot: ' + startTime.to_s
          #puts "\n"

          start_history_records = get_start_history_records(route, direction, startStop, startTime, isWeekend)

          stop_distance_times = get_stop_distance_times(start_history_records, startStop, endStop, route, direction)

          #remove outliers
          unless stop_distance_times.empty? or stop_distance_times.count < 5
            mean_distance_time = ::TravelTimeCalculator.interquartile_mean(stop_distance_times).to_i

            puts 'mean distance time: ' + mean_distance_time.to_s

            StopSlot.create(route_id: route.route_id, direction: direction, stop_id: endStop.stop_id, is_weekend: isWeekend, time_slot: startTime, distance_time: mean_distance_time)
          end

          startTime += hourInterval
        end
      end

      #if we loop through and grab the bearings from each we should be able to get only ones a certain direction from the desired point.
    end
  end
end

def get_start_history_records(route, direction, startStop, startTime, isWeekend)
  weekend_query = isWeekend ? " AND extract('ISODOW' FROM time) > 5" : "AND extract('ISODOW' FROM time) < 6"

  find_records = lambda {
      BusHistory.near(
        [startStop.stop_lat, startStop.stop_lon]).where(
        'route = ? AND direction = ? AND EXTRACT(HOUR FROM time) BETWEEN ? AND ?' + weekend_query,
        route.route_short_name,
        direction,
        startTime,
        startTime + 2
    ).order('distance').limit(100)
  }
                                              rv
  SuperGeocoder.new.geocode_them_all(find_records, data)
end

def get_stop_distance_times(start_history_records, startStop, endStop, route, direction)
  stop_distance = startStop.distance_to(endStop)
  puts 'stop distance in miles: ' + stop_distance.to_s

  stop_distance_times = []
  start_history_records.each do |start_record|

    find_stop_record = lambda {
      BusHistory.near(
          [endStop.stop_lat, endStop.stop_lon], 1).where(
          'route = ? AND direction = ? AND vehicle_id = ? AND time BETWEEN ? AND ?',
          route.route_short_name,
          direction,
          start_record.vehicle_id,
          start_record.time + 1.seconds,
          start_record.time + 1.hours
      )
      .order('distance').limit(1).first
    }

    stop_record = SuperGeocoder.new.geocode_them_all(find_stop_record, data)

    if stop_record
      record_distance = stop_record.distance_to(start_record)
      record_transit_time = (stop_record.time - start_record.time).to_i
      speed = record_distance / record_transit_time if record_transit_time > 0 #miles per second
      distance_time = (stop_distance / speed).to_i unless speed.nil? or speed == 0 or speed < 0.0001

      unless distance_time.nil?
        stop_distance_times.push(distance_time)

        #puts 'record distance: ' + record_distance.to_s
        #puts 'stop record id: ' + stop_record.id.to_s
        #puts 'start record id: ' + start_record.id.to_s
        #puts 'start record time: ' + start_record.time.to_s
        #puts 'stop record time: ' + stop_record.time.to_s
        #puts 'record transit time: ' + record_transit_time.to_s
        #puts 'speed: ' + speed.to_s
        #puts 'distance time: ' + distance_time.to_s
        #puts "\n"
      end
    end
  end

  return stop_distance_times
end

#SimplifiedStop.near('315 Manton St, Philadelphia PA 19147', 0.1).where('route_id = ? AND route_direction_id = ?', '11325', 180).order('distance').limit(1)


# section is defined as stop to stop. so store stop info for all routes,

# on request - find next stop, then grab all the stops between that one and target and calculate the time it usually takes for it to do those

# we're not going to have data exactly on stops, it'll be right before or after. so for each stop lets use the last recorded time before the stop and
# then the next time after last stop and use that speed multiplied by the distance between the desired stops to compute the section. so store the total seconds it takes to cross each section.
# then we can just add up all the seconds between the stops they need to go through.


#return all sections between first and second stop
#get_sections(first_stop, second_stop)
