require "rails_helper"
require "rack/test"

RSpec.describe NutritionAnalysis::CreateLog do
  let(:user) do
    User.create!(email: "service@example.com", provider: "google_oauth2", uid: "svc-1")
  end

  describe "#call" do
    it "persists a food log when macros are provided" do
      result = described_class.new(user:, params: {
        food_name: "Oatmeal",
        calories: 300,
        protein_g: 10,
        fats_g: 5,
        carbs_g: 55
      }).call

      expect(result).to be_success
      expect(result.food_log).to be_persisted
      expect(result.food_log.food_name).to eq("Oatmeal")
    end

    it "delegates to the analyzer when macros are blank" do
      analyzer = instance_double(
        NutritionAnalysis::VisionClient,
        analyze: NutritionAnalysis::VisionClient::Analysis.new(
          success?: true,
          food_name: "AI Salad",
          macros: { calories: 200, protein_g: 6, fats_g: 10, carbs_g: 18 }
        )
      )

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

      result = described_class.new(
        user:,
        params: { food_name: "Unknown", photo: file },
        analyzer:
      ).call

      expect(result).to be_success
      expect(result.food_log.food_name).to eq("AI Salad")
      expect(result.food_log.calories).to eq(200)
    end

    it "returns an error when the analyzer fails" do
      analyzer = instance_double(
        NutritionAnalysis::VisionClient,
        analyze: NutritionAnalysis::VisionClient::Analysis.new(
          success?: false,
          error_message: "API unavailable"
        )
      )

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

      result = described_class.new(
        user:,
        params: { food_name: "Unknown", photo: file },
        analyzer:
      ).call

      expect(result).not_to be_success
      expect(result.error_message).to eq("API unavailable")
      expect(result.food_log).not_to be_persisted
    end
  end
end
