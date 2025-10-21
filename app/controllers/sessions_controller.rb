class SessionsController < ApplicationController
<<<<<<< HEAD
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
    redirect_to path, success: "Welcome back, #{current_user.email}!"
  rescue StandardError => e
    Rails.logger.error("OAuth login failed: #{e.message}")
    redirect_to root_path, alert: "We could not sign you in. Please try again."
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, success: "Signed out successfully."
  end

  def failure
    redirect_to root_path, alert: params[:message] || "Google sign-in failed."
  end

  private

  def symbolized_auth(auth)
    (auth.respond_to?(:to_h) ? auth.to_h : auth).deep_symbolize_keys
=======
  # This handles the /auth/failure route
  def failure
    flash[:alert] = "Authentication failed. Please try again."
    redirect_to root_path
  end

  # This handles the /auth/google_oauth2/callback route
  def omniauth
    auth = request.env["omniauth.auth"]

    # This line will now work because the controller can find the User model
    @user = User.find_or_create_by(uid: auth["uid"], provider: auth["provider"]) do |u|
      u.email = auth["info"]["email"]
    end

    session[:user_id] = @user.id

    if @user.height_cm.nil? || @user.weight_kg.nil?
      flash[:notice] = "Welcome! Please complete your profile."
      # This next line will still cause an error, but that's for Ticket 6
      redirect_to edit_user_path(@user)
    else
      flash[:notice] = "Signed in successfully."
      redirect_to root_path
    end
  end

  # This handles the DELETE /sign_out route
  def destroy
    session[:user_id] = nil
    flash[:notice] = "Signed out successfully."
    redirect_to root_path
>>>>>>> cc7cdad230a336ee234e8e0c612ecb7822b64a4b
  end
end
