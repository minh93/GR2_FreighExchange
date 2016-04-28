class AbstractTrip < ActiveRecord::Base
  self.table_name = "abstract_trip"

  has_many :trips

  belongs_to :supplier
  belongs_to :StartPoint, class_name: "Location", foreign_key: "start_point"
  belongs_to :EndPoint, class_name: "Location", foreign_key: "end_point"
end