class Customer::SchedulesController < Customer::BaseController
  
  def index
    @request = Request.find_by_request_id params[:request_id]
    @schedules = @request.schedules
  end

  def update
    #Change status trip and request
    @schedule = Schedule.find_by_schedule_id params[:id]

    @schedule.status = "finished"
    @schedule.save
    
    @schedule.invoices.each do |invoice|
      invoice.status = "finished"
      invoice.save      
    end

    @schedule.request.status = "finished"
    @schedule.request.save

    flash[:success] = 'Lorem ipsum dolosit amet.'
    redirect_to customer_requests_path
  end 
end