class SuperGeocoder

  #Pass in a lambda and any other variables it needs access to as an instance variable
  def geocode_them_all(lambda, argument=nil)
    @services = [
        {:lookup => :google, :api => ''},
        {:lookup => :geocoder_ca, :api => ''},
        {:lookup => :mapquest, :api => 'Fmjtd%7Cluur2l6zn1%2C2n%3Do5-901luu'},
        {:lookup => :bing, :api => 'AhjXP6MLVgO_sMwYI0jICW_2ZMuNcSfvX6YeMbDKqPcqRgfIYnSCXxzQfqdad9cM'},
        {:lookup => :ovi, :api => ''},
    ].shuffle

    @argument = argument

    @lambda = lambda

    geocode

  end

  def geocode(index=0)

    service = @services[index]

    begin
      @lambda.call(@argument)
    rescue => e
      Rails.logger.error(e)
      if index == @services.count
        return
      end
      geoconfig(service)
      geocode(index + 1)
      return
    end
  end

  def geoconfig(service)
    puts 'using api service ' + service[:lookup].to_s
    Rails.logger.info('using api service ' + service[:lookup].to_s)
    Geocoder.configure(
        :lookup => service[:lookup],
        :api_key => service[:api]
    )
  end
end