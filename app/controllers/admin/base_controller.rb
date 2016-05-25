class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_admin

  private
  def validate_admin
    unless current_user.role == "admin"
      flash[:danger] = "Only admin can access this page"
      redirect_to "root_path"
    end
  end
end
