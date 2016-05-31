class Supplier::InvoicesController < Supplier::BaseController
  def update
    invoice = Invoice.find_by invoice_id: params[:id]
    @request = Request.find_by request_id: invoice.request_id

    flash[:success] = 'Accepted'
    redirect_to edit_supplier_request_path(@request)
  end
end
