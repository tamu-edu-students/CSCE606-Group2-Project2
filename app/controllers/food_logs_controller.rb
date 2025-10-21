class FoodLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_food_log, only: :destroy

  def index
    @food_logs = current_user.food_logs.with_attached_photo.order(created_at: :desc)
  end

  def new
    @food_log = current_user.food_logs.build
  end

  def create
    service = NutritionAnalysis::CreateLog.new(user: current_user, params: food_log_params)
    result = service.call

    if result.success?
      redirect_to dashboard_path, success: "Food log saved."
    else
      @food_log = result.food_log
      flash.now[:alert] = result.error_message || "We could not analyze that item. Please try again."
      render :new, status: :unprocessable_entity
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
end
