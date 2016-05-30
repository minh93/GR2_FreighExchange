class Customer::InvoicesController < Customer::BaseController
  def update
    invoice = Invoice.find_by invoice_id: params[:id]
    invoice.update_attributes status: :accepted

    #Create message notify to supplier

    flash[:success] = 'Accepted this proposal'
    redirect_to customer_requests_path
  end
end