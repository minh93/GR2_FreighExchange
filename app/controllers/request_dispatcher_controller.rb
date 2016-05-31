class RequestDispatcherController < ApplicationController
  before_action :authenticate_user!

  def main
    case current_user.role
    when "admin"
      redirect_to controller: "admin/home", action: "index"
    when "customer"
      redirect_to root_path
    when "supplier"
      redirect_to root_path
    when nil      
      redirect_to controller: "error", action: "index", error_code: "403", message: "User not active"
    else
      @error_code = "405"
      @message = "Method not allowed"
      render "error_pages/error"
    end
  end

  def app_dispatcher
    app_name = params[:app_name];
    if app_name == "delivery"
      if current_user.role == "customer"
        redirect_to customer_requests_path
      elsif current_user.role == "supplier"
        redirect_to supplier_requests_path
      else
        @error_code = "401"
        @message = "Unauthorized request."
        render "error_pages/error"
      end
    elsif app_name == "mail_box"
      redirect_to notification_index_path
    elsif app_name == "payment"
      if current_user.role == "customer"
        redirect_to customer_invoices_path
      elsif current_user.role == "supplier"
        redirect_to supplier_invoices_path
      else
        @error_code = "401"
        @message = "Unauthorized request."
        render "error_pages/error"
      end
    else
      @error_code = "###"
      @message = "Application currently developing."
      render "error_pages/error"
    end
  end
end
