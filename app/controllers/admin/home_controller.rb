require "DAL"
class Admin::HomeController < Admin::BaseController
  before_action :override_breadcrumb
  def index
  end  

  private
  def override_breadcrumb
    @breadcrumb = ["Admin","Home page"]
  end
end
