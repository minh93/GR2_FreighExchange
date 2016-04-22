class Trip < ActiveRecord::Base
  self.table_name = "trip"
  
  belongs_to :schedule
  belongs_to :abstract_trip
end