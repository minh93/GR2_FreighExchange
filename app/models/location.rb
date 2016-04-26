require "DAL"
class Location < ActiveRecord::Base
  self.table_name = "location"

  #Return nearest location, if no return nil
  def self.find_nearest_point long, lat
    return DAL.findNearestPoint(long, lat)
  end
end