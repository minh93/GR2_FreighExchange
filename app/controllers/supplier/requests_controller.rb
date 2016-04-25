class Supplier::RequestsController < Supplier::BaseController
  before_action :authenticate_user!
  before_action :request_is_approved?

  def show
    @request = Request.find_by_request_id params[:id]
    @breadcrumb = [current_user.role,"detailed request"]
    render "share/request/show"
  end

  # Approve request and create invoice record
  def approve
    @request = Request.find_by_request_id(params[:request_id])
    if @request.nil?
      flash[:danger] = "No request found"
      redirect_to requests_path
    else
      newInvoice = @request.invoices.build
      #In this context current user always be supplier
      #FIXME: Check role ?
      
      newInvoice.offer_price = params[:offer_price]
      newInvoice.supplier_id = Supplier.find_by_user_id(current_user.id).supplier_id
      newInvoice.message = params[:message]
      newInvoice.save

      flash[:notice] = "Successful approve request"
      redirect_to controller: "requests", action: "show", id: @request.id
    end
  end

  private
  def request_is_approved?
    invoice = Invoice.find_by request_id: params[:id], supplier_id: Supplier.find_by_user_id(current_user.id).supplier_id
    if invoice.nil?
      @show_approve_form = true
    else
      @show_approve_form = false
    end
  end
end
