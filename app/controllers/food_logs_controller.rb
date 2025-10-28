class FoodLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_food_log, only: %i[edit update destroy]

  def index
    @sort = safe_sort_param(params[:sort])
    @direction = params[:direction] == "asc" ? "asc" : "desc"

    logs = current_user.food_logs.with_attached_photo
    if @sort == "date"
      logs = logs.order(created_at: (@direction == "asc" ? :asc : :desc))
    else
      logs = logs.order(created_at: :desc)
    end

    @grouped_logs = logs.group_by { |l| l.created_at.to_date }
  end

  def new
    @food_log = current_user.food_logs.build
  end

  def create
    service = NutritionAnalysis::CreateLog.new(user: current_user, params: food_log_params)
    result = service.call

    if result.success?
      if current_user.survey_completed?
        redirect_to dashboard_path, success: "Food log saved."
      else
        # If the user hasn't completed onboarding they will be sent to the
        # onboarding flow by the dashboard; redirect directly to the onboarding
        # page so the success flash is shown on the landing page.
        redirect_to new_onboarding_path, success: "Food log saved."
      end
    else
      @food_log = result.food_log
      flash.now[:alert] = result.error_message || "We could not analyze that item. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    permitted_params = food_log_params
    update_attrs = permitted_params.to_h
    update_attrs.delete("photo") if update_attrs["photo"].blank?

    if should_trigger_analysis?(permitted_params)
      result = NutritionAnalysis::UpdateLog.new(food_log: @food_log, params: permitted_params).call

      if result.success?
        redirect_to dashboard_path, success: "Food log updated."
      else
        @food_log = result.food_log
        flash.now[:alert] = result.error_message || "We couldn't update this food entry."
        render :edit, status: :unprocessable_entity
      end
    elsif @food_log.update(update_attrs)
      redirect_to dashboard_path, success: "Food log updated."
    else
      flash.now[:alert] = "We couldn't update this food entry."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @food_log.destroy
    redirect_to dashboard_path, success: "Entry removed."
  end

  private

  def set_food_log
    @food_log = current_user.food_logs.find(params[:id])
  end

  def food_log_params
    params.require(:food_log).permit(:food_name, :calories, :protein_g, :fats_g, :carbs_g, :photo)
  end

  def should_trigger_analysis?(params)
    params[:photo].present? && macro_fields_blank?(params)
  end

  def macro_fields_blank?(params)
    %i[calories protein_g fats_g carbs_g].all? { |key| params[key].blank? }
  end

  def safe_sort_param(value)
    %w[date calories protein_g fats_g carbs_g].include?(value) ? value : "date"
  end
end
