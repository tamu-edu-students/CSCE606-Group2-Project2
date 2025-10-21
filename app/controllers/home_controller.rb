class HomeController < ApplicationController
  def index
    return unless user_signed_in?

    redirect_to(current_user.survey_completed? ? dashboard_path : new_onboarding_path)
  end
end
