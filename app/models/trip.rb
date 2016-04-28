class Trip < ActiveRecord::Base
  self.table_name = "trip"

  after_create :create_notification

  belongs_to :schedule
  belongs_to :abstract_trip

  has_many :notifications, as: :targetable

  scope :open_trip, ->{joins(:schedule).where(schedule: {status: 'open'})}

  private
  def create_notification
    supplier = self.abstract_trip.supplier
    self.notifications.create! user_id: supplier.user.id, 
      message: "New trip need attention!", 
      level: "user",
      is_read: false
  end
end