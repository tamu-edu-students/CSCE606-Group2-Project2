class ProfilesController < ApplicationController
  before_action :authenticate_user!

  # PATCH /profile/goals
  def update_goals
    # Support two modes:
    # - direct manual goal updates (daily_* fields)
    # - calories_left: user edits the remaining calories for today; convert to a stored daily_calories_goal
    if params[:calories_left].present?
      # compute consumed calories for today and derive a new daily_calories_goal
      consumed = current_user.todays_food_logs.sum(:calories).to_i
      wanted_remaining = params[:calories_left].to_i
      new_goal = consumed + wanted_remaining

      if current_user.update(daily_calories_goal: new_goal)
        render json: { success: true, user: { daily_calories_goal: current_user.daily_calories_goal, calories_left: wanted_remaining } }
      else
        render json: { success: false, errors: current_user.errors.full_messages }, status: :unprocessable_entity
      end
      return
    end

    permitted = params.permit(:daily_calories_goal, :daily_protein_goal_g, :daily_fats_goal_g, :daily_carbs_goal_g)

    # Convert blank strings to nil so validations behave
    sanitized = permitted.to_h.transform_values { |v| v == "" ? nil : v }

    if current_user.update(sanitized)
      render json: { success: true, user: { daily_calories_goal: current_user.daily_calories_goal, daily_protein_goal_g: current_user.daily_protein_goal_g, daily_fats_goal_g: current_user.daily_fats_goal_g, daily_carbs_goal_g: current_user.daily_carbs_goal_g } }
    else
      render json: { success: false, errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
