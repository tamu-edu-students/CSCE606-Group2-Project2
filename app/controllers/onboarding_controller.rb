class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def new
    set_measurement_context(nil)
    if @user.survey_completed?
      flash.now[:notice] = "Updating your profile will recalculate today's goals."
    end
  end

  def create
    raw_params = raw_onboarding_params
    set_measurement_context(raw_params)
    normalized_params = MeasurementParamsNormalizer.normalize(raw_params)

    if @user.complete_survey!(normalized_params)
      redirect_to dashboard_path, success: "Goals calculated successfully."
    else
      flash.now[:alert] = "Please correct the highlighted errors."
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Please correct the highlighted errors."
    render :new, status: :unprocessable_entity
  end

  private

  def set_user
    @user = current_user
  end

  def raw_onboarding_params
    params.require(:user).permit(
      :username,
      :sex,
      :date_of_birth,
      :height_input,
      :weight_input,
      :height_cm,
      :weight_kg,
      :activity_level,
      :goal_type,
      :daily_calories_goal,
      :daily_protein_goal_g,
  :daily_fats_goal_g,
  :daily_carbs_goal_g,
      :measurement_system
    )
  end

  def set_measurement_context(raw_params)
    raw_hash =
      case raw_params
      when ActionController::Parameters
        raw_params.to_h
      when Hash
        raw_params
      else
        {}
      end

    @form_params = raw_hash.transform_keys(&:to_s)
    selected_system = @form_params["measurement_system"].presence || params[:measurement_system]
    @measurement_system = selected_system.presence || "metric"
    @form_params["measurement_system"] = @measurement_system
    apply_default_measurements
  end

  def apply_default_measurements
    @form_params["height_input"] ||= default_height_input
    @form_params["weight_input"] ||= default_weight_input
  end

  def default_height_input
    return "" unless @user.height_cm.present?

    if @measurement_system == "imperial"
      total_inches = (@user.height_cm / MeasurementParamsNormalizer::CM_PER_INCH).round
      feet = total_inches / MeasurementParamsNormalizer::IMPERIAL_INCHES_PER_FOOT
      inches = total_inches % MeasurementParamsNormalizer::IMPERIAL_INCHES_PER_FOOT
      "#{feet}'#{inches}\""
    else
      @user.height_cm.round.to_s
    end
  end

  def default_weight_input
    return "" unless @user.weight_kg.present?

    if @measurement_system == "imperial"
      pounds = @user.weight_kg / MeasurementParamsNormalizer::KG_PER_POUND
      format("%.1f", pounds)
    else
      format("%.1f", @user.weight_kg)
    end
  end
end
