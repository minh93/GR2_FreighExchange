class Supplier < ActiveRecord::Base
	self.table_name = "supplier"
	
  has_many :vehicles
  has_many :abstract_trips

  belongs_to :user
end