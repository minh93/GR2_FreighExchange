class Customer::TrackingController < Customer::BaseController
  def index
    @request = Request.all[rand(Request.all.count)]
  end

  def get_itineary
    schedule = Schedule.find_by_schedule_id(params[:schedule_id])
    @pointsInJouney = Array.new

    schedule.trips.each do |trip|
      @pointsInJouney << trip.abstract_trip.StartPoint
      @pointsInJouney << trip.abstract_trip.EndPoint
    end

    render :json => @pointsInJouney
  end
end