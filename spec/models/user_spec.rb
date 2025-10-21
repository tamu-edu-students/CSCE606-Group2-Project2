require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) do
    described_class.create!(
      email: "person@example.com",
      provider: "google_oauth2",
      uid: "uid-123",
      height_cm: 180,
      weight_kg: 80,
      date_of_birth: Date.new(1994, 1, 1),
      sex: "male",
      activity_level: :moderately_active,
      goal_type: :maintain,
      survey_completed: true
    )
  end

  describe "validations" do
    it "requires email, provider, and uid" do
      invalid = described_class.new
      expect(invalid).not_to be_valid
      expect(invalid.errors[:email]).to be_present
      expect(invalid.errors[:provider]).to be_present
      expect(invalid.errors[:uid]).to be_present
    end

    it "validates positive numeric attributes" do
      invalid = described_class.new(
        email: "example@test.com",
        provider: "google_oauth2",
        uid: "123",
        height_cm: -10,
        weight_kg: -5
      )

      expect(invalid).not_to be_valid
      expect(invalid.errors[:height_cm]).to include("must be greater than 0")
      expect(invalid.errors[:weight_kg]).to include("must be greater than 0")
    end
  end

  describe ".find_or_create_from_auth_hash" do
    let(:auth_hash) do
      {
        provider: "google_oauth2",
        uid: "auth-123",
        info: { email: "new_user@example.com" }
      }
    end

    it "creates a user with provider and uid" do
      result = described_class.find_or_create_from_auth_hash(auth_hash)
      expect(result).to be_persisted
      expect(result.email).to eq("new_user@example.com")
    end

    it "does not duplicate existing users" do
      existing = described_class.create!(
        email: "existing@example.com",
        provider: "google_oauth2",
        uid: "auth-123"
      )

      result = described_class.find_or_create_from_auth_hash(auth_hash)
      expect(result.id).to eq(existing.id)
    end
  end

  describe "#calculate_goals!" do
    it "computes nutrition targets using Mifflin St-Jeor" do
      travel_to Date.new(2024, 1, 1) do
        user.update!(survey_completed: false)
        user.calculate_goals!

        expect(user.daily_calories_goal).to be_between(2500, 2800)
        expect(user.daily_protein_goal_g).to eq(144)
        expect(user.daily_fats_goal_g).to eq(64)
        expect(user.daily_carbs_goal_g).to be_between(350, 450)
      end
    end
  end

  describe "#remaining_macros_for_today" do
    it "subtracts today's food logs" do
      user.update!(
        daily_calories_goal: 2000,
        daily_protein_goal_g: 150,
        daily_fats_goal_g: 70,
        daily_carbs_goal_g: 230
      )

      user.food_logs.create!(food_name: "Breakfast", calories: 500, protein_g: 30, fats_g: 20, carbs_g: 40)
      travel_to Time.zone.now.change(hour: 18) do
        user.food_logs.create!(food_name: "Lunch", calories: 600, protein_g: 40, fats_g: 25, carbs_g: 50)
      end

      remaining = user.remaining_macros_for_today

      expect(remaining[:calories]).to eq(900)
      expect(remaining[:protein_g]).to eq(80)
      expect(remaining[:fats_g]).to eq(25)
      expect(remaining[:carbs_g]).to eq(140)
    end
  end

  describe "#todays_food_logs" do
    it "returns only entries from the current day" do
      today_log = user.food_logs.create!(food_name: "Salad", calories: 300, protein_g: 10, fats_g: 5, carbs_g: 20)
      travel_to 2.days.ago do
        user.food_logs.create!(food_name: "Old", calories: 100, protein_g: 5, fats_g: 2, carbs_g: 10)
      end

      expect(user.todays_food_logs).to contain_exactly(today_log)
    end
  end

  describe "#complete_survey!" do
    it "updates survey flag and recalculates goals" do
      user.update!(survey_completed: false)
      user.complete_survey!(activity_level: :lightly_active, goal_type: :lose)

      expect(user).to be_survey_completed
      expect(user.daily_calories_goal).to be_positive
    end
  end
end
