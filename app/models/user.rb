class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable

  has_many :notifications, dependent: :destroy

  scope :search, ->query{where "name LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%"}
  
  def get_detailed_info
    if self.role == "customer"
      Customer.find_by user_id: self.id
    elsif self.role == "supplier"
      Supplier.find_by user_id: self.id
    end
  end

  def active_for_authentication?
    !self.role.nil?
  end

  def inactive_message
    "Sorry, this account is not active."
  end

  def block
    update_attributes blocked_at: Time.now
  end

  def unblock
    update_attributes blocked_at: nil
  end

  def blocked?
    !self.blocked_at.nil?
  end

  def update_role new_role
    update_attributes role: new_role
  end

  def reset_password
    #FIXME
    return true
  end
end
