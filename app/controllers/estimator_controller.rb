require 'net/http'
require 'json'

class EstimatorController < ActionController::Base
  protect_from_forgery
  @@busNum = 0

  def estimate(startingBus = false)
    @route = params[:route]
    @direction = params[:direction]
    stop_id = params[:stop_id]

    uri = URI.parse("http://www3.septa.org/hackathon/Stops/" + @route.to_s)

    response = Net::HTTP.get_response(uri)

    response = JSON.parse response.body
    response.each do |stopInfo|
      if stopInfo['stopid'].to_s == stop_id
        @latitude = stopInfo['lat']
        @longitude = stopInfo['lng']
      end
    end

    if @latitude.nil?
      render :json => 'Could not find stop info'
      return
    end



    #12th and chestnut, route 23
    #16131

    #broad and chestnut, route 4
    #estimate/23/NorthBound/15185

    #federal and 11th stop
    #estimate/23/NorthBound/16832
    #@route = 23
    #@longitude = -75.16194
    #@latitude = 39.934726
    #@direction = "NorthBound"

    buses = getNextBusesToArrive
    if startingBus
      nextToArrive = buses[startingBus]
    else
      nextToArrive = buses.first
    end

	render :json => nextToArrive
	return

    vehicleData = getStartHistoricalData(nextToArrive)

    #render :json => [nextToArrive, vehicleData]
    #return

    historicalData = getHistoricalData(vehicleData)

    #render :json => historicalData
    #return

    #remove outliers
    finalHistoricalDataGroup = getFinalHistoricalDataGroup(historicalData)

    puts 'final group'
    p finalHistoricalDataGroup

    finalArrivalData = getFinalArrivalData(finalHistoricalDataGroup, nextToArrive)

    if finalArrivalData
      if finalArrivalData[:time_to_arrive] <= 0
        return estimate(@@busNum + 1)
      else
        render :json => {
            'time to arrive' => finalArrivalData[:time_to_arrive].to_s + ' minutes',
            'vehicle' => nextToArrive['VehicleID'],
            'm/s' => finalArrivalData[:meters_per_sec],
            'distance' => finalArrivalData[:distance],
            'start' => nextToArrive['lat'].to_s + ', ' + nextToArrive['lng'],
            'end' => @latitude.to_s + ', ' + @longitude.to_s
        }
        return
      end
    end

    render :json => nextToArrive

  end

  def getFinalArrivalData(finalHistoricalDataGroup, nextToArrive)
    if !finalHistoricalDataGroup.empty?

      distanceTotal = 0
      timeDiffTotal = 0
      finalHistoricalDataGroup.each do |historicalDatum|
        distanceTotal += historicalDatum[:distance]
        timeDiffTotal += historicalDatum[:time_diff]
      end

      distanceAvg = distanceTotal / finalHistoricalDataGroup.count
      timeDifAvg = timeDiffTotal / finalHistoricalDataGroup.count

      distanceInMeters = distanceAvg * 100000

      metersPerSec = distanceInMeters / timeDifAvg
      #metersPerSec *= 2

      #TODO compute real distance with google maps api

      distance =  (@latitude - nextToArrive['lat'].to_f).abs + (@longitude - nextToArrive['lng'].to_f).abs
      distance *= 100000

      case @direction
        when 'NorthBound', 'SouthBound'
          distance =  (@latitude - nextToArrive['lat'].to_f).abs
        when 'EastBound', 'WestBound'
          distance =  (@longitude - nextToArrive['lng'].to_f).abs
      end

      distance *= 100000

      timeUntilBusArrives = (((distance / metersPerSec) / 60) - nextToArrive['Offset'].to_i).round

      return {:time_to_arrive => timeUntilBusArrives, :meters_per_sec => metersPerSec, :distance => distance}
    end
  end

  def getFinalHistoricalDataGroup(historicalData)
    #group into distances
    groups = getHistoricalDataGroups(historicalData)

    finalHistoricalDataGroup = []
    shortestTime = 99999999

    groups.each do |group|
      puts 'processing group'
      p group

      groupSample = group.first

      finalHistoricalDataGroup = group if groupSample[:time_diff] < shortestTime
    end

    return finalHistoricalDataGroup
  end

  def getHistoricalDataGroups(historicalData)
    groups = []
    historicalData.each do |historicalDatum|
      foundGroup = false
      secondsThreshold = 100
      distanceThreshold = 0.003

      if groups.empty?
        groups.push [historicalDatum]
        foundGroup = true
      else
        groups.each_with_index do |group, index|
          groupSample = group.first
          withinTimeThresholdOfAverage = (historicalDatum[:time_diff] > (groupSample[:time_diff] - secondsThreshold) and historicalDatum[:time_diff] < (groupSample[:time_diff] + secondsThreshold))
          #puts 'bottom dist thresh ' + (groupSample[:distance] - distanceThreshold).to_s
          #puts 'top dist thresh ' + (groupSample[:distance] + distanceThreshold).to_s
          #puts 'current historical datum ' + historicalDatum[:distance].to_s
          withinDistanceThresholdOfAverage = (historicalDatum[:distance] > (groupSample[:distance] - distanceThreshold) and historicalDatum[:distance] < (groupSample[:distance] + distanceThreshold))
          if withinTimeThresholdOfAverage and withinDistanceThresholdOfAverage
            groups[index].push historicalDatum
            foundGroup = true
            next
          end
        end
      end

      if !foundGroup
        groups.push [historicalDatum]
      end
    end

    return groups
  end

  def getHistoricalData(vehicleData)
    historicalData = []
    vehicleData.each do |vehicleDatum|
      vehicleId = vehicleDatum[:vehicle_id]
      vehicleStartTime = Time.parse(vehicleDatum[:time]) + 1.minutes
      vehicleEndTime = vehicleStartTime + 1.hours

      #find closest to destination coords, store distance/time diff

      puts 'start: ' + vehicleStartTime.to_s
      puts 'end: ' + vehicleEndTime.to_s

      rows = ActiveRecord::Base.connection.execute("
        SELECT longitude, latitude, time
        FROM bus_history
        WHERE
          route = '#{@route}'
          AND vehicle_id = #{vehicleId}
          AND time between '#{vehicleStartTime.to_s}'
          AND '#{vehicleEndTime.to_s}';
      ")

      rows = rows.to_a.sort {
          |busDataA, busDataB|

        case @direction
          when 'NorthBound', 'SouthBound'
            distanceA = (@latitude - busDataA['latitude'].to_f).abs
            distanceB = (@latitude - busDataB['latitude'].to_f).abs
          when 'EastBound', 'WestBound'
            distanceA = (@longitude - busDataA['longitude'].to_f).abs
            distanceB = (@longitude - busDataB['longitude'].to_f).abs
        end

        distanceA <=> distanceB
      }
      #render :json => [nextToArrive, rows]
      #return

      closestEndData = rows.first

      if closestEndData
        #TODO compute road distance using google maps api
        case @direction
          when 'NorthBound', 'SouthBound'
            distance = vehicleDatum[:lat].to_f - closestEndData['latitude'].to_f
          when 'EastBound', 'WestBound'
            distance = vehicleDatum[:long].to_f - closestEndData['longitude'].to_f
        end

        puts "distance: " + distance.abs.to_s
        timeDiff = Time.parse(closestEndData['time']) - vehicleStartTime
        puts "time diff: " + timeDiff.to_s
        historicalData.push({:distance => distance.abs, :time_diff => timeDiff})
      end

    end

    return historicalData
  end

  def getStartHistoricalData(nextToArrive)
    vehicleData = []
    if nextToArrive
      nextToArriveLat = nextToArrive['lat']
      nextToArriveLong = nextToArrive['lng']

      #TODO take current time into account
      timeA = (Time.now - 1.weeks).strftime('%Y-%m-%d')
      timeB = (Time.now - 2.weeks).strftime('%Y-%m-%d %H')
      timeC = (Time.now - 3.weeks).strftime('%Y-%m-%d %H')
      rows = ActiveRecord::Base.connection.execute("
          SELECT
            distinct(vehicle_id), id, longitude, latitude, direction, time
          FROM bus_history
          WHERE
            route = '#{@route}'
            AND direction = '#{@direction}'
            AND latitude::text like '#{nextToArriveLat.to_s.slice(0, 5)}%'
            AND longitude::text like '#{nextToArriveLong.to_s.slice(0, 6)}%'
          limit 10
        ")
      #AND time between '#{timeA}' and '#{Time.now}'

      #render :json => [nextToArrive, rows]
      #return

      rows = rows.to_a.sort {
          |busDataA, busDataB|

        case @direction
          when 'NorthBound', 'SouthBound'
            distanceA = (nextToArriveLat.to_f - busDataA['latitude'].to_f).abs
            distanceB = (nextToArriveLat.to_f - busDataB['latitude'].to_f).abs
          when 'EastBound', 'WestBound'
            distanceA = (nextToArriveLong.to_f - busDataA['longitude'].to_f).abs
            distanceB = (nextToArriveLong.to_f - busDataB['longitude'].to_f).abs
        end

        distanceA <=> distanceB
      }

      rows.each do |row|
        vehicleData.push({:vehicle_id => row['vehicle_id'], :lat => row['latitude'], :long => row['longitude'], :time => row['time']})
      end
    end
    return vehicleData
  end

  def getNextBusesToArrive
    uri = URI.parse("http://www3.septa.org/hackathon/TransitView/" + @route.to_s)

    begin

      response = Net::HTTP.get_response(uri)

      if response.body != 'Invalid Route'
        response = JSON.parse response.body
        response['bus'].keep_if {
            |bus|

          if bus['Direction'] == @direction
            case @direction
              when 'NorthBound'
                bus['lat'].to_f < @latitude
              when 'SouthBound'
                bus['lat'].to_f > @latitude
              when 'WestBound'
                bus['long'].to_f < @longitude
              when 'EastBound'
                bus['long'].to_f > @longitude
            end
          end
        }

        #response
        # ['bus'][array of buses][lat | lng | VehicleID | BlockId | Direction | destination | Offset]

        sortedBuses = response['bus'].sort {
            |bus1, bus2|
          bus1Distance = (@latitude - bus1['lat'].to_f).abs + (@longitude - bus1['lng'].to_f).abs
          bus2Distance = (@latitude - bus2['lat'].to_f).abs + (@longitude - bus2['lng'].to_f).abs
          bus1Distance <=> bus2Distance
        }

        return sortedBuses
      end
    end
  end
end


#build a table of bus info