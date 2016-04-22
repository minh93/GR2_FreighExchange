class AbstractTrip < ActiveRecord::Base
  self.table_name = "abstract_trip"

  has_many :trips
end