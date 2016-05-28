class Trip < ActiveRecord::Base
  self.table_name = "trip"
  #Return constant delay time
  #15 min per trip
  DELAY_TIME = 300

  after_create :create_notification

  belongs_to :schedule
  belongs_to :abstract_trip
  belongs_to :vehicle

  has_many :notifications, as: :targetable

  scope :open_trip, ->{joins(:schedule).where(schedule: {status: 'open'})}
  scope :available, ->(supplier){joins(:abstract_trip).where(abstract_trip: {supplier_id: supplier.id})}

  private
  def create_notification
    supplier = self.abstract_trip.supplier
    self.notifications.create! user_id: supplier.user.id, 
      message: "New trip need attention!", 
      level: "user",
      is_read: false
  end
end