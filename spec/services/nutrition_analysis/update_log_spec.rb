require "rails_helper"
require "rack/test"

RSpec.describe NutritionAnalysis::UpdateLog do
  let(:user) do
    User.create!(email: "update@example.com", provider: "google_oauth2", uid: "u-1")
  end

  let(:food_log) do
    FoodLog.create!(user:, food_name: "Toast", calories: 150, protein_g: 4, fats_g: 6, carbs_g: 20)
  end

  describe "#call" do
    it "updates the food log when macros are provided" do
      result = described_class.new(food_log:, params: { calories: 200, protein_g: 6, fats_g: 8, carbs_g: 24 }).call

      expect(result).to be_success
      expect(result.food_log.reload.calories).to eq(200)
      expect(result.food_log.protein_g).to eq(6)
    end

    it "delegates to the analyzer when a photo is provided and macros are blank" do
      analyzer = instance_double(
        NutritionAnalysis::VisionClient,
        analyze: NutritionAnalysis::VisionClient::Analysis.new(
          success?: true,
          food_name: "AI Sandwich",
          macros: { calories: 320, protein_g: 12, fats_g: 10, carbs_g: 36 }
        )
      )

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

      result = described_class.new(food_log:, params: { food_name: "Unknown", photo: file }, analyzer: analyzer).call

      expect(result).to be_success
      expect(result.food_log.food_name).to eq("AI Sandwich")
      expect(result.food_log.calories).to eq(320)
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

      result = described_class.new(food_log:, params: { food_name: "Unknown", photo: file }, analyzer: analyzer).call

      expect(result).not_to be_success
      expect(result.error_message).to eq("API unavailable")
      # original food_log remains persisted but errors were attached
      expect(result.food_log).to be_present
    end

    it "returns an error when saving the analyzed food_log fails" do
      analyzer = instance_double(
        NutritionAnalysis::VisionClient,
        analyze: NutritionAnalysis::VisionClient::Analysis.new(
          success?: true,
          food_name: "AI Salad",
          macros: { calories: 120, protein_g: 5, fats_g: 2, carbs_g: 10 }
        )
      )

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

  # Force the underlying save to fail on this specific instance and provide error messages
  allow(food_log).to receive(:save).and_return(false)
  allow(food_log).to receive_message_chain(:errors, :full_messages).and_return([ "DB write failed" ])

      result = described_class.new(food_log:, params: { food_name: "Unknown", photo: file }, analyzer: analyzer).call

      expect(result).not_to be_success
      expect(result.error_message).to include("DB write failed")
    end

    it "preserves the existing food_name when analyzer returns blank food_name" do
      analyzer = instance_double(
        NutritionAnalysis::VisionClient,
        analyze: NutritionAnalysis::VisionClient::Analysis.new(
          success?: true,
          food_name: nil,
          macros: { calories: 200, protein_g: 8, fats_g: 6, carbs_g: 30 }
        )
      )

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

  # Do not supply a food_name in params so the analyzer's blank name will not
  # overwrite the original stored name (Toast)
  result = described_class.new(food_log:, params: { photo: file }, analyzer: analyzer).call

  expect(result).to be_success
  expect(result.food_log.food_name).to eq("Toast")
      expect(result.food_log.calories).to eq(200)
    end

    it "does not call the analyzer when macros are provided even if a photo is present" do
      analyzer = instance_double(NutritionAnalysis::VisionClient)
      expect(analyzer).not_to receive(:analyze)

      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")

      result = described_class.new(food_log:, params: { photo: file, calories: 180, protein_g: 5, fats_g: 4, carbs_g: 22 }, analyzer: analyzer).call

      expect(result).to be_success
      expect(result.food_log.calories).to eq(180)
    end

    it "exposes helper behavior via its private methods (filtered_params, macro_fields_blank?, requires_analysis?)" do
      ul = described_class.new(food_log: food_log, params: { food_name: "X", calories: "", protein_g: "", fats_g: "", carbs_g: "", photo: nil })

      # filtered_params should slice known keys
      fp = ul.send(:filtered_params)
      expect(fp).to include(:food_name)

      # with all macro fields blank macro_fields_blank? => true
      expect(ul.send(:macro_fields_blank?)).to be(true)

      # requires_analysis? is false when no photo
      expect(ul.send(:requires_analysis?)).to be(false)

      # when a photo is present and macros blank, requires_analysis? is true
      ul_with_photo = described_class.new(food_log: food_log, params: { photo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg"), calories: nil, protein_g: nil, fats_g: nil, carbs_g: nil })
      expect(ul_with_photo.send(:macro_fields_blank?)).to be(true)
      expect(ul_with_photo.send(:requires_analysis?)).to be(true)
    end
  end
end
