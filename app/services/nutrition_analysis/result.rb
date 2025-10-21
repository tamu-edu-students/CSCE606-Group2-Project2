module NutritionAnalysis
  class Result
    attr_reader :food_log, :error_message

    def initialize(food_log:, error_message: nil)
      @food_log = food_log
      @error_message = error_message
    end

    def success?
      error_message.nil? && food_log.present? && food_log.persisted?
    end
  end
end
