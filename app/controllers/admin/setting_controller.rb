require "DAL"
class Admin::SettingController < Admin::BaseController
  def index
  end

  def update
    if params[:admin_action] == "checkstatus"
      action_checkstatus
    end
  end

  def action_checkstatus
    Request.check_status_request
    @requests = Request.where(:status => ['remind1', 'remind2', 'expired'])
    @requests.each do |request|
      if request.status == 'remind1'
        user_customer_id = Customer.find_by_customer_id(request.customer_id).user_id    
        request.notifications.create! user_id: user_customer_id, 
        message: "Your request has first reminder!", 
        level: "user",
        is_read: false
      elsif request.status == 'remind2'
        user_customer_id = Customer.find_by_customer_id(request.customer_id).user_id    
        request.notifications.create! user_id: user_customer_id, 
        message: "Your request has second reminder!", 
        level: "user",
        is_read: false
      else
        user_customer_id = Customer.find_by_customer_id(request.customer_id).user_id    
        request.notifications.create! user_id: user_customer_id, 
        message: "Your request has been expired!", 
        level: "user",
        is_read: false
      end
    end
    redirect_to admin_setting_index_path
  end

  private
  def override_breadcrumb
    @breadcrumb = ["Admin","System setting"]
  end  
end