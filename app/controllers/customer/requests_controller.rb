require "GoogleAPI"

class Customer::RequestsController < Customer::BaseController
  def index
    @requests = current_user.get_detailed_info.
      requests.get_all.order(created_at: :DESC).
        paginate(:page => params[:page], :per_page => 10)
  end

  def show
    @request = current_user.get_detailed_info.requests.find(params[:id])
    render "share/request/show"
  end

  def new
    @request = Request.new    
  end

  def edit
    @request = Request.find params[:id]
  end

  def create
    @request = current_user.get_detailed_info.requests.build submit_params
    
    request_is_valid = false

    begin
      @request.time = DateTime.strptime(submit_params[:time], '%m/%d/%Y %H:%M %p')
      @request.start_point_lat = submit_params[:start_point_lat].to_f
      @request.start_point_long = submit_params[:start_point_long].to_f
      @request.end_point_lat = submit_params[:end_point_lat].to_f
      @request.end_point_long = submit_params[:end_point_long].to_f

      # Check input location has already been in location db
      start_point = Location.find_nearest_point(@request.start_point_long, @request.start_point_lat)
      end_point = Location.find_nearest_point(@request.end_point_long, @request.end_point_lat)

      @request.start_point = start_point if start_point != nil
      @request.end_point = end_point if end_point != nil

      #Estimate distance by google service
      distance = GoogleAPI.new().distanceEstimate(@request.start_point_lat,
        @request.start_point_long,
        @request.end_point_lat,
        @request.end_point_long)

      if !distance.nil?
        @request.distance_estimate = distance.to_i
      end

      #Set request status = 'open'      
      @request.status = "none"

      request_is_valid = true
    rescue => exception
      @error_message = exception.message
      request_is_valid = false
    end

    respond_to do |format|
      if request_is_valid && @request.save
        format.html { flash[:success] = 'Your request successfully created.'
          redirect_to customer_requests_path }
        format.json { render :show, status: :created, location: @request }
      else        
        format.html { flash[:danger] = 'Something went wrong! ' + @error_message
          render :new }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @request = Request.find params[:id]
    # review code
    @request.update_attribute("time", DateTime.strptime(submit_params[:time], '%m/%d/%Y %H:%M %p'))
    @request.save
    respond_to do |format|
      if @request.update(submit_params)
        format.html { flash[:success] = 'Your request successfully updated.'
          redirect_to customer_requests_path }
        format.json { render :show, status: :ok, location: @user_goal }
      else
        format.html { render :edit }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @request = Request.find params[:id]
    @request.status = "deleted"
    @request.save
    respond_to do |format|
      format.html { flash[:danger] = "Your request successfully destroyed."
        redirect_to customer_requests_path}
      format.json { head :no_content }
    end
  end

  private

  def submit_params
    params.require(:request).permit :weight, :goods_type, :height, :length, :capacity, :time, 
      :start_point_lat, :start_point_long, :end_point_lat, :end_point_long, 
        :category_id, :goods_type, :other_description
  end
end
