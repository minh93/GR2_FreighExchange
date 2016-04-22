class Supplier::HomeController < Supplier::BaseController
  before_action :authenticate_user!
  
  def index
    @breadcrumb = ["Supplier","Browse requests"]
    
  end
end
