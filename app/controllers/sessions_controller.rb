class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create
  skip_before_action :set_current_user, only: :create

  def new
    @authorization_url = "/auth/google_oauth2"
  end

  def create
    auth = request.env["omniauth.auth"]
    @current_user = User.find_or_create_from_auth_hash(symbolized_auth(auth))
    session[:user_id] = current_user.id

  path = current_user.survey_completed? ? dashboard_path : new_onboarding_path
  display_name = current_user.username.presence || current_user.email
  redirect_to path, success: "Welcome back, #{display_name}!"
  rescue StandardError => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "We could not sign you in. Please try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, success: "Signed out successfully."
  end

  def failure
  raw = params[:message].to_s
  raw = request.env["omniauth.error.type"].to_s if raw.blank? && request.env["omniauth.error.type"]
  raw = request.env["omniauth.error"].to_s if raw.blank? && request.env["omniauth.error"]
    friendly = case raw
    when /invalid_credentials/i, /access_denied/i
                 "Authentication was canceled."
    when /csrf_detected|authenticity_token|invalid_request/i
                 "Authentication request could not be verified; please try again."
    else
                 "Google sign-in failed."
    end

    redirect_to root_path, alert: friendly
  end

  private

  def symbolized_auth(auth)
    (auth.respond_to?(:to_h) ? auth.to_h : auth).deep_symbolize_keys
  end
end
