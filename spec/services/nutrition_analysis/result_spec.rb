require "rails_helper"

RSpec.describe NutritionAnalysis::Result do
  let(:user) { User.create!(email: "r@example.com", provider: "google_oauth2", uid: "r-1") }

  it "is successful when given a persisted food_log and no error message" do
    log = FoodLog.create!(user:, food_name: "Eggs", calories: 200, protein_g: 12, fats_g: 10, carbs_g: 2)
    result = described_class.new(food_log: log)

    expect(result.success?).to be true
  end

  it "is not successful when the food_log is not persisted" do
    log = FoodLog.new(user:, food_name: "Draft", calories: 0, protein_g: 0, fats_g: 0, carbs_g: 0)
    result = described_class.new(food_log: log)

    expect(result.success?).to be false
  end

  it "is not successful when an error_message is present" do
    log = FoodLog.create!(user:, food_name: "Eggs", calories: 200, protein_g: 12, fats_g: 10, carbs_g: 2)
    result = described_class.new(food_log: log, error_message: "something broke")

    expect(result.success?).to be false
  end
end
