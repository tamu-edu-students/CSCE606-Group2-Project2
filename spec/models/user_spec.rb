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

  describe "#calories_balance_for_today" do
    before do
      user.update!(daily_calories_goal: 2_000)
    end

    it "returns positive balance when under the limit" do
      user.food_logs.create!(food_name: "Salad", calories: 500, protein_g: 10, fats_g: 5, carbs_g: 10)

      expect(user.calories_balance_for_today).to eq(1_500)
    end

    it "returns zero or negative when over the limit" do
      user.food_logs.create!(food_name: "Snack", calories: 2_100, protein_g: 10, fats_g: 5, carbs_g: 10)

      expect(user.calories_balance_for_today).to eq(-100)
    end
  end

  describe "#over_calorie_limit?" do
    before do
      user.update!(daily_calories_goal: 1_800)
    end

    it "is false when under the goal" do
      expect(user.over_calorie_limit?).to be(false)
    end

    it "is true when the user has no calories remaining" do
      user.food_logs.create!(food_name: "Buffet", calories: 1_900, protein_g: 20, fats_g: 10, carbs_g: 30)

      expect(user.over_calorie_limit?).to be(true)
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

  describe "#validate_calculated_goals!" do
    it "logs warnings when calculated goals are outside expected ranges" do
      # Create a small user to call the private method via send
      u = described_class.create!(
        email: "warn@example.com",
        provider: "google_oauth2",
        uid: "warn-1",
        height_cm: 180,
        weight_kg: 80,
        date_of_birth: Date.new(1990, 1, 1),
        sex: "male",
        activity_level: :very_active,
        goal_type: :gain,
        survey_completed: true
      )

      extreme_goals = {
        daily_calories_goal: 10_000,
        daily_protein_goal_g: 9999,
        daily_fats_goal_g: 9999,
        daily_carbs_goal_g: 9999
      }

      expect(Rails.logger).to receive(:warn).at_least(:once)
      u.send(:validate_calculated_goals!, extreme_goals).tap do |ret|
        expect(ret).to be_truthy
      end
    end
  end

  describe "age and clamps" do
    it "clamps age under 18 to 18" do
      u = described_class.create!(
        email: "young@example.com",
        provider: "google_oauth2",
        uid: "y-1",
        height_cm: 160,
        weight_kg: 50,
        date_of_birth: Date.today - 10.years,
        sex: "female",
        activity_level: :sedentary,
        goal_type: :maintain,
        survey_completed: true
      )

      expect(u.send(:age_in_years)).to eq(18)
    end

    it "clamps age over 100 to 100" do
      u = described_class.create!(
        email: "old@example.com",
        provider: "google_oauth2",
        uid: "o-1",
        height_cm: 160,
        weight_kg: 60,
        date_of_birth: Date.new(1900, 1, 1),
        sex: "female",
        activity_level: :sedentary,
        goal_type: :maintain,
        survey_completed: true
      )

      expect(u.send(:age_in_years)).to eq(100)
    end
  end

  describe "calculation helpers" do
    it "complete_survey! saves when manual goals provided" do
      u = described_class.create!(
        email: "manual@example.com",
        provider: "google_oauth2",
        uid: "m-1",
        height_cm: 170,
        weight_kg: 70,
        date_of_birth: Date.new(1990, 1, 1),
        sex: "male",
        activity_level: :moderately_active,
        goal_type: :maintain,
        survey_completed: false
      )

      u.complete_survey!(daily_calories_goal: 1800)
      expect(u.reload.survey_completed).to be(true)
      expect(u.daily_calories_goal).to eq(1800)
    end

    it "returns a calculation breakdown and goals comparison" do
      u = described_class.create!(
        email: "comp@example.com",
        provider: "google_oauth2",
        uid: "c-1",
        height_cm: 170,
        weight_kg: 70,
        date_of_birth: Date.new(1990, 1, 1),
        sex: "male",
        activity_level: :moderately_active,
        goal_type: :maintain,
        survey_completed: true
      )

      bd = u.calculation_breakdown
      expect(bd).to include(:bmr, :tdee, :final_calories)

      gc = u.goals_comparison
      expect(gc[:calories]).to include(:current, :calculated, :difference)
    end
  end

  describe "auto recalculation" do
    it "recalculates goals after save when relevant attributes change" do
      u = described_class.create!(
        email: "auto@example.com",
        provider: "google_oauth2",
        uid: "auto-1",
        height_cm: 170,
        weight_kg: 70,
        date_of_birth: Date.new(1990, 1, 1),
        sex: "male",
        activity_level: :moderately_active,
        goal_type: :maintain,
        survey_completed: true
      )

      expect_any_instance_of(described_class).to receive(:calculate_goals!).once
      u.update!(weight_kg: 75)
    end
  end

  describe "private helpers coverage" do
    it "returns correct activity multipliers for known levels" do
      u = subject
      expect(u.send(:activity_multiplier)).to be_within(0.001).of(1.55)

      u.activity_level = :sedentary
      expect(u.send(:activity_multiplier)).to be_within(0.001).of(1.2)

      u.activity_level = :very_active
      expect(u.send(:activity_multiplier)).to be_within(0.001).of(1.725)
    end

    it "applies goal adjustments for lose/gain/maintain" do
      u = subject
      u.goal_type = :lose
      expect(u.send(:goal_adjustment)).to eq(-500)

      u.goal_type = :gain
      expect(u.send(:goal_adjustment)).to eq(300)

      u.goal_type = :maintain
      expect(u.send(:goal_adjustment)).to eq(0)
    end

    it "basal_metabolic_rate differs by sex" do
      m = described_class.create!(email: "m2@example.com", provider: "g", uid: "m2", height_cm: 180, weight_kg: 80, date_of_birth: Date.new(1990, 1, 1), sex: "male", activity_level: :moderately_active, goal_type: :maintain, survey_completed: true)
      f = described_class.create!(email: "f2@example.com", provider: "g", uid: "f2", height_cm: 180, weight_kg: 80, date_of_birth: Date.new(1990, 1, 1), sex: "female", activity_level: :moderately_active, goal_type: :maintain, survey_completed: true)

      expect(m.send(:basal_metabolic_rate)).to be > f.send(:basal_metabolic_rate)
    end

    it "calculated_daily_carbs clamps at zero when remaining calories negative" do
      u = described_class.create!(email: "c@example.com", provider: "g", uid: "c", height_cm: 160, weight_kg: 60, date_of_birth: Date.new(1990, 1, 1), sex: "male", activity_level: :sedentary, goal_type: :maintain, survey_completed: true)

      carbs = u.send(:calculated_daily_carbs, calories: 100, protein: 50, fats: 20)
      expect(carbs).to eq(0)
    end

    it "normalize_email_and_sex lowercases values on validation" do
      u = described_class.new(email: "UPPER@EX.COM", provider: "g", uid: "nz-1", sex: "MALE")
      u.valid?
      expect(u.email).to eq("upper@ex.com")
      expect(u.sex).to eq("male")
    end
  end
end
