require "DAL"
class Request < ActiveRecord::Base
  self.table_name = "request"

  after_create :create_notification
  after_create :auto_find_best_ways

  scope :opened, -> {where status: ["none", "pending"]}
  scope :get_all, -> {where.not status: "deleted"}

  belongs_to :customer
  has_many :invoices
  has_many :notifications, as: :targetable
  has_many :schedules

  # def self.check_status_request
  #   ActiveRecord::Base.connection.execute("SELECT check_request_time('2 days', '4 days', '6 days')")
  # end

  def is_expired
    if self.status == "none" || self.status == "pending"
      return false
    else
      return true
    end
  end

  def renew
    update_attributes status: "none"
  end

  private
  def create_notification
    user_customer_id = Customer.find_by_customer_id(self.customer_id).user_id    
    self.notifications.create! user_id: user_customer_id, 
    message: "Your request has been recorded!", 
    level: "user",
    is_read: false
  end

  #FIXME: Background job
  def auto_find_best_ways
    result_1 = DAL.containRouting(self.start_point_long, self.start_point_lat, self.end_point_long, self.end_point_lat)
    user_customer_id = Customer.find_by_customer_id(self.customer_id).user_id    
    if result_1 != 0
      result_2 = DAL.pgrDijkstraFromAtoB(self.start_point_long, self.start_point_lat, self.end_point_long, self.end_point_lat)      
      #Create and save schedule to db, level SYSTEM, status open
      #FIXME add more infomation for schedule, time ...
      tem_array_abstract_trip_id = Array.new
      
      result_2.values.each do |item|
        hash_arr = JSON.parse(item[0])
        tem_array_abstract_trip_id << hash_arr["abstract_trip_id"]        
      end

      self.schedules.create! level: "system",
        status: "open",
        abstract_trips: tem_array_abstract_trip_id
      #Create notification
      tem_msg = String.new
      result_2.values.each do |item|
        hash_arr = JSON.parse(item[0])
        tem_msg << hash_arr["name"]
        tem_msg << ">>>"
      end
      self.notifications.create! user_id: user_customer_id, 
        message: "Found #{result_1} nodes in best ways #{tem_msg}", 
        level: "system",
        is_read: false
    else
      #Create direct schedule
      new_trip = AbstractTrip.create!(category_id: self.category_id,
        start_point: self.start_point,
        end_point: self.end_point,
        is_persistence: true)
      tem_array_abstract_trip_id = Array.new
      tem_array_abstract_trip_id << new_trip.id
      self.schedules.create! level: "system",
        status: "open",
        abstract_trips: tem_array_abstract_trip_id
      self.notifications.create! user_id: user_customer_id, 
        message: "Direct request has been created!", 
        level: "system",
        is_read: false
    end
  end
end
