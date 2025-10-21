class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :set_current_user

  helper_method :current_user, :user_signed_in?

  add_flash_types :success, :warning

  private

  def set_current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if user_signed_in?

    redirect_to root_path, warning: "Please sign in with Google to continue."
  end
end
