require "rails_helper"

RSpec.describe FoodLog, type: :model do
  let(:user) do
    User.create!(
      email: "food@example.com",
      provider: "google_oauth2",
      uid: "food-1"
    )
  end

  it "is invalid without required macros" do
    log = described_class.new(user:, food_name: "Salad")
    expect(log).not_to be_valid
    expect(log.errors[:calories]).to include("is not a number")
  end

  it "is valid with numeric macros" do
    log = described_class.new(
      user:,
      food_name: "Salad",
      calories: 120,
      protein_g: 8,
      fats_g: 5,
      carbs_g: 12
    )

    expect(log).to be_valid
  end

  describe "#macros" do
    it "returns a hash of macro totals" do
      log = described_class.create!(
        user:,
        food_name: "Salad",
        calories: 120,
        protein_g: 8,
        fats_g: 5,
        carbs_g: 12
      )

      expect(log.macros).to eq({ calories: 120, protein_g: 8, fats_g: 5, carbs_g: 12 })
    end
  end
end
