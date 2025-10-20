class SessionsController < ApplicationController
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
  end
end
