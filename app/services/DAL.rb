class DAL
  #Routing function
  #Check contain route. Return 0 if not found
  def self.containRouting start_lat, start_lon, end_lat, end_lon
    record_array = ActiveRecord::Base.connection.execute("select contain_routing(#{start_lat}, #{start_lon}, #{end_lat}, #{end_lon});")
    result = (record_array.values[0][0]).to_i
    return result
  end

  def self.pgrDijkstraFromAtoB start_lat, start_lon, end_lat, end_lon
    record_array = ActiveRecord::Base.connection.execute("select row_to_json(pgr_dijkstra_fromAtoB(#{start_lat}, #{start_lon}, #{end_lat}, #{end_lon}));")
    return record_array 
  end
  #Find id of nearest point. Return 0 if not found
  def self.findNearestPoint long, lat
    record_array = ActiveRecord::Base.connection.execute("select nearest_point(#{lat}, #{long})")
    result = (record_array.values[0][0]).to_i
    if result != 0
      return result
    else
      return nil
    end
  end
end