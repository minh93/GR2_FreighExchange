class DAL
  def self.callProc
    record_array = ActiveRecord::Base.connection.execute("select contain_routing(105.8469019, 21.0243218, 105.8440137, 21.0285599);")
    return record_array
  end

  def self.containRouting start_lon, start_lat, end_lon, end_lat
    record_array = ActiveRecord::Base.connection.execute("select contain_routing(#{start_lon}, #{start_lat}, #{end_lon}, #{end_lat});")
    result = (record_array.values[0][0]).to_i
    return result
  end

  def self.pgrDijkstraFromAtoB start_lon, start_lat, end_lon, end_lat
    record_array = ActiveRecord::Base.connection.execute("select row_to_json(pgr_dijkstra_fromAtoB(#{start_lon}, #{start_lat}, #{end_lon}, #{end_lat}));")
    return record_array 
  end
end