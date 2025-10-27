module NutritionAnalysis
  class UpdateLog
    def initialize(food_log:, params:, analyzer: VisionClient.new)
      @food_log = food_log
      @params = params
      @analyzer = analyzer
    end

    def call
      food_log.assign_attributes(filtered_params)

      if requires_analysis?
        analysis_result = analyzer.analyze(image: params[:photo], food_name: params[:food_name].presence || food_log.food_name)
        if analysis_result.success?
          food_log.assign_attributes(analysis_result.macros)
          food_log.food_name = analysis_result.food_name.presence || food_log.food_name
        else
          food_log.errors.add(:base, analysis_result.error_message)
          return Result.new(food_log:, error_message: analysis_result.error_message)
        end
      end

      if food_log.save
        Result.new(food_log:)
      else
        Result.new(food_log:, error_message: food_log.errors.full_messages.to_sentence)
      end
    end

    private

    attr_reader :food_log, :params, :analyzer

    def filtered_params
      params.slice(:food_name, :calories, :protein_g, :fats_g, :carbs_g, :photo)
    end

    def requires_analysis?
      params[:photo].present? && macro_fields_blank?
    end

    def macro_fields_blank?
      %i[calories protein_g fats_g carbs_g].all? { |key| params[key].blank? }
    end
  end
end
