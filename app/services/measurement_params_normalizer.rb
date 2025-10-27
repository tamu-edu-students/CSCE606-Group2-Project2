class MeasurementParamsNormalizer
  IMPERIAL_INCHES_PER_FOOT = 12
  CM_PER_INCH = 2.54
  KG_PER_POUND = 0.45359237

  def self.normalize(params)
    new(params).normalize
  end

  def initialize(params)
    @params =
      case params
      when ActionController::Parameters
        params.to_unsafe_h
      when Hash
        params
      else
        {}
      end.with_indifferent_access
    @measurement_system = (@params.delete(:measurement_system)&.presence || "metric")
  end

  def normalize
    convert_height!
    convert_weight!
    @params.slice!(
      :username,
      :sex,
      :date_of_birth,
      :height_cm,
      :weight_kg,
      :activity_level,
      :goal_type,
      :daily_calories_goal,
      :daily_protein_goal_g,
      :daily_fats_goal_g,
      :daily_carbs_goal_g
    )
    @params
  end

  private

  def convert_height!
    height_input = @params.delete(:height_input)
    return if height_input.blank? && present_numeric?(@params[:height_cm])

    @params[:height_cm] =
      if measurement_imperial?
        convert_imperial_height(height_input)
      else
        numeric_height(height_input)
      end
  end

  def convert_weight!
    weight_input = @params.delete(:weight_input)
    return if weight_input.blank? && present_numeric?(@params[:weight_kg])

    @params[:weight_kg] =
      if measurement_imperial?
        convert_imperial_weight(weight_input)
      else
        numeric_weight(weight_input)
      end
  end

  def measurement_imperial?
    @measurement_system == "imperial"
  end

  def present_numeric?(value)
    value.present? && value.to_f.positive?
  end

  def numeric_height(input)
    value = parse_number(input)
    value&.round
  end

  def numeric_weight(input)
    value = parse_number(input)
    value&.round(1)
  end

  def parse_number(input)
    return nil if input.blank?

    Float(input)
  rescue ArgumentError, TypeError
    nil
  end

  def convert_imperial_height(input)
    inches = parse_imperial_height_in_inches(input)
    return nil if inches.nil?

    (inches * CM_PER_INCH).round
  end

  def parse_imperial_height_in_inches(input)
    str = input.to_s.strip.downcase
    return nil if str.blank?

    str = str.gsub(/feet|ft/, "'").gsub(/inches|inch|in/, "\"")

    if str.include?("'")
      match = str.match(/\A(?<feet>\d+)\s*'\s*(?<inches>\d+(?:\.\d+)?)?\s*"?\z/)
      return nil unless match

      feet = match[:feet].to_f
      inches = match[:inches].presence&.to_f || 0
      feet * IMPERIAL_INCHES_PER_FOOT + inches
    elsif str.match?(/"|in/)
      match = str.match(/\A(?<inches>\d+(?:\.\d+)?)\s*(?:"|in)?\z/)
      match ? match[:inches].to_f : nil
    else
      # treat as decimal feet
      feet = parse_number(str)
      feet ? feet * IMPERIAL_INCHES_PER_FOOT : nil
    end
  end

  def convert_imperial_weight(input)
    pounds = parse_number(strip_weight_units(input))
    return nil if pounds.nil?

    (pounds * KG_PER_POUND).round(1)
  end

  def strip_weight_units(input)
    input.to_s.strip.downcase.gsub(/lbs?|pounds?/, "")
  end
end
