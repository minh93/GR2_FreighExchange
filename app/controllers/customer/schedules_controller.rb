class Customer::SchedulesController < Customer::BaseController
  
  def index
    @request = Request.find_by_request_id params[:request_id]
    @schedules = @request.schedules
  end

  def update
    #Choose best price for trip
    @schedule = Schedule.find_by_schedule_id params[:schedule_id]
    
    redirect_to customer_requests_path
  end 
end