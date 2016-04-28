class Schedule < ActiveRecord::Base
  self.table_name = "schedule"

  belongs_to :request
  
  has_many :trips
  has_many :invoices

  serialize :abstract_trips
end