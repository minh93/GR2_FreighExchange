class Customer::TripsController < Customer::BaseController
  def create
    #TODO: Create list of trip, or specific trip and abstract trip
    @schedule = Schedule.find_by_schedule_id params[:schedule_id]
    #Auto create trips if level [system]
    if (@schedule.level == "system") && (@schedule.abstract_trips != nil)
      @schedule.abstract_trips.each_with_index do |abstract_trip_id, index|
        @schedule.trips.create!(sequent: index, abstract_trip_id: abstract_trip_id.to_i)        
      end
    end

    redirect_to customer_requests_path
  end
end