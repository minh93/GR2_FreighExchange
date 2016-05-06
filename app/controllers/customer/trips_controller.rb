class Customer::TripsController < Customer::BaseController
  
  def create    
    @schedule = Schedule.find_by_schedule_id params[:schedule_id]
    #Create trips if level [system]
    if (@schedule.level == "system") && (@schedule.abstract_trips != nil)
      @schedule.abstract_trips.each_with_index do |abstractTripId, index|
        abstractTrip = AbstractTrip.find_by_abstract_trip_id(abstractTripId.to_i)
        @schedule.trips.create!(sequent: index, abstract_trip_id: abstractTrip.id, 
          source: abstractTrip.source, target: abstractTrip.target, is_reverse_trip: false)        
      end
    end
    #Check reverse trip
    trips = @schedule.trips.order(:sequent)
    trips.each_with_index do |trip, index|
      if index > 0
        if trips[index -1].target != trip.source
          temVal = trip.source
          trip.source = trip.target
          trip.target = temVal
          trip.is_reverse_trip = true
          trip.save          
        end
      end
    end

    redirect_to customer_requests_path
  end  
end