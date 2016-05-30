class Supplier::RequestsController < Supplier::BaseController
  before_action :authenticate_user!
  before_action :request_is_approved?

  def index
    @breadcrumb = [current_user.role,"Open requests"]    
    @supplier = current_user.get_detailed_info
    @trips = Trip.available(@supplier)
      .open_trip
      .paginate(:page => params[:page], :per_page => 10)
    @requests = Request.where(status: "none")
  end

  def show
    @breadcrumb = [current_user.role,"detailed request"]
    typeOfRequest = params[:type]
    if typeOfRequest == "request"
      @request = Request.find_by_request_id(params[:id])
      costPerKm = Vehicle.find_by_category_id(@request.category_id).cost_per_km
      @estimateCost = (@request.distance_estimate * costPerKm)/1000
      render "share/request/show"
    elsif typeOfRequest == "trip"        
      @trip = Trip.find_by_trip_id params[:id]
    end
  end

  # Approve request and create invoice record
  def approve
    request = Request.find_by_request_id(params[:request_id])
    trip = Trip.find_by_trip_id(params[:trip_id])
    if request.nil?
      flash[:danger] = "No request found"
      redirect_to supplier_requests_path
    else
      trip.vehicle_id = params[:vehicle_id]
      trip.save      

      newInvoice = request.invoices.build
      newInvoice.supplier_id = current_user.get_detailed_info.id
      newInvoice.trip_id = trip.id
      newInvoice.vehicle_id = params[:vehicle_id]
      newInvoice.schedule_id = trip.schedule_id
      newInvoice.offer_price = params[:offer_price]
      newInvoice.supplier_id = Supplier.find_by_user_id(current_user.id).supplier_id
      newInvoice.message = params[:message]
      newInvoice.save

      flash[:notice] = "Successful approve request"
      redirect_to controller: "requests", action: "show", id: trip.id, type: "trip"
    end
  end

  def send_proposal
    request = Request.find_by_request_id(params[:request_id])    
    if request.nil?
      flash[:danger] = "No request found"
      redirect_to supplier_requests_path
    else
      newInvoice = request.invoices.build
      newInvoice.supplier_id = current_user.get_detailed_info.id
      newInvoice.offer_price = params[:offer_price]
      newInvoice.supplier_id = Supplier.find_by_user_id(current_user.id).supplier_id
      newInvoice.message = params[:message]
      newInvoice.save
    end
      flash[:notice] = "Successful approve request"
      redirect_to controller: "requests", action: "show", id: request.id, type: "request"
  end

  private
  def request_is_approved?
    @invoice = Invoice.find_by trip_id: params[:id], supplier_id: current_user.get_detailed_info.id
    if @invoice.nil?
      @show_approve_form = true
    else
      @show_approve_form = false
    end
  end
end
