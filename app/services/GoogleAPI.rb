require "rubygems"
require "json"
require "net/http"

class GoogleAPI
  def initialize()
    @apiKey = "AIzaSyA10aWgd-daSGzR3ruieu5MgbGAxusiF90"        
  end

  def distanceEstimate start_lat, start_long, end_lat, end_long
    mapDistanceMatrixUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{start_lat},#{start_long}&destinations=#{end_lat},#{end_long}&key=#{@apiKey}"
    #Try catch with http request
    begin
      #Call google map api
      url = URI.parse(mapDistanceMatrixUrl)
      result = Net::HTTP::get(url)
      #Parse json string to hash variable 
      @parsed = JSON.parse(result)
      if @parsed["status"] == "OK" && @parsed["rows"].first()["elements"].first()["status"] == "OK"
        @distance = @parsed["rows"].first()["elements"].first()["distance"]["value"]
      else 
        @distance = -1
      end
    rescue StandardError
      false
    end
  end

  def getLocationName lat, long
    mapLocationInfoUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{long}&key=#{@apiKey}"
    begin
      url = URI.parse(mapLocationInfoUrl)
      result = Net::HTTP::get(url)
      @parsed = JSON.parse(result)
      if @parsed["status"] == "OK"
        @locationName = @parsed["results"].first()["formatted_address"]
      else 
        @locationName = ""
      end
    rescue StandardError => e
      e
    end
  end
end
