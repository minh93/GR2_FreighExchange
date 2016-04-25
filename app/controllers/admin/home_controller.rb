require "DAL"
class Admin::HomeController < Admin::BaseController
  def index
    #TEST
   # @results = DAL.pgrDijkstraFromAtoB(105.8469019, 21.0243218, 105.849755, 21.021964)
  end

  def checkstatus
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
  	redirect_to admin_home_path
  end

  def checkaction    
    redirect_to admin_home_path
  end
end
