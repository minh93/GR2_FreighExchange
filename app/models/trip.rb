class Trip < ActiveRecord::Base
  self.table_name = "trip"

  belongs_to :schedule
  belongs_to :abstract_trip

  scope :open_trip, ->{joins(:schedule).where(schedule: {status: 'open'})}
end