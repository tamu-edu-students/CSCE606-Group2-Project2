class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_survey_completed

  def show
    @remaining_macros = current_user.remaining_macros_for_today
    @calories_balance = current_user.calories_balance_for_today
    @todays_logs = current_user.todays_food_logs
  end

  private

  def ensure_survey_completed
    return if current_user.survey_completed?

    # Preserve any existing flash (e.g. a success message from a previous redirect)
    flash[:alert] ||= "Please complete the onboarding survey first."
    redirect_to new_onboarding_path
  end
end
