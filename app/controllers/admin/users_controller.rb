require "DAL"
class Admin::UsersController < Admin::BaseController  
  before_action :override_breadcrumb
  before_action :load_user, only: [:destroy, :update, :show]
  
  def index
    if params[:search]
      @users = User.search(params[:search])
      .paginate page: params[:page], per_page: 10
    else
      @users = User.paginate page: params[:page], per_page: 10
    end
  end

  def update
    if params[:admin_action] == "block"
      action_block
    elsif params[:admin_action] == "edit_role"
      action_edit_role
    elsif params[:admin_action] == "reset_password"
      action_reset_password
    end
  end

  def show
    redirect_to root_path if @user.nil?
  end  

  private
  def load_user
    @user = User.find params[:id] if User.exists? params[:id]
  end

  def action_block
    @user.blocked? ? @user.unblock : @user.block
    redirect_to admin_users_path
  end

  def action_edit_role
    @user = User.find params[:user_id]
    if @user.update_role params[:new_role]
      render json: {message: "Done"},
      status: :ok
    else
      render json: {message: "Error has occured"},
      status: :internal_server_error
    end
  end

  def action_reset_password
    if @user.reset_password
      render json: {message: "Password reset"},
      status: :ok
    else
      render json: {message: "Error has occured"},
      status: :internal_server_error
    end
  end

  

  private
  def override_breadcrumb
    @breadcrumb = ["Admin","User management"]
  end
end
