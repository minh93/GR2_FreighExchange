class NotificationController < ApplicationController
  before_action :authenticate_user!

  def index
    @all_messages = current_user.notifications.
      order(created_at: :DESC).
        paginate(:page => params[:page], :per_page => 7)
  end

  def show
    @all_messages = current_user.notifications.
      order(created_at: :DESC).
        paginate(:page => params[:page], :per_page => 7)
    @current_message = current_user.notifications.find_by_notification_id params[:id]
    @current_message.is_read = true
    @current_message.save
  end
end