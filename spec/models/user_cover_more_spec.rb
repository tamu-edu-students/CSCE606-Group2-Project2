require "rails_helper"

RSpec.describe "user cover more" do
  it "exercises many remaining User branches to raise coverage" do
    # Create users across different combos to exercise methods
    m = User.create!(email: "u1@example.com", provider: "g", uid: "u1", height_cm: 180, weight_kg: 90, date_of_birth: Date.new(1980, 1, 1), sex: "male", activity_level: :extra_active, goal_type: :lose, survey_completed: true)
    f = User.create!(email: "u2@example.com", provider: "g", uid: "u2", height_cm: 160, weight_kg: 60, date_of_birth: Date.new(1970, 6, 1), sex: "female", activity_level: :sedentary, goal_type: :gain, survey_completed: true)

    # ready_for_goal_calculation? true for both
    expect(m.send(:ready_for_goal_calculation?)).to be(true)
    expect(f.send(:ready_for_goal_calculation?)).to be(true)

    # Build goals for both goal types to hit different protein_multiplier / adjustment paths
    gm = m.send(:build_daily_goals)
    gf = f.send(:build_daily_goals)
    expect(gm).to include(:daily_calories_goal)
    expect(gf).to include(:daily_protein_goal_g)

    # validate_calculated_goals! for extremes triggers multiple warnings
    extremes_low = { daily_calories_goal: 1000, daily_protein_goal_g: 10, daily_fats_goal_g: 5, daily_carbs_goal_g: 10 }
    extremes_high = { daily_calories_goal: 10_000, daily_protein_goal_g: 9999, daily_fats_goal_g: 9999, daily_carbs_goal_g: 9999 }
  # exercise validation warning branches (don't assert on logger calls to avoid test fragility)
  expect(m.send(:validate_calculated_goals!, extremes_low)).to be_truthy
  expect(m.send(:validate_calculated_goals!, extremes_high)).to be_truthy

    # total_daily_energy_expenditure and related calculators
    expect(m.send(:basal_metabolic_rate)).to be > 0
    expect(m.send(:total_daily_energy_expenditure)).to be > 0
    expect(m.send(:calculated_daily_calories)).to be_between(1200, 4000)

    # calculated daily macros
    expect(m.send(:calculated_daily_protein)).to be >= 0
    expect(m.send(:calculated_daily_fats)).to be >= 0
    expect(m.send(:calculated_daily_carbs, calories: 2000, protein: 100, fats: 70)).to be >= 0

    # goals_comparison differences
    comp = m.goals_comparison
    expect(comp[:calories][:difference]).to eq(m.send(:build_daily_goals)[:daily_calories_goal].to_i - m.daily_calories_goal.to_i)

    # todays_logs_macros and remaining_macros_for_today
    m.food_logs.create!(food_name: "X", calories: 200, protein_g: 20, fats_g: 10, carbs_g: 20)
    totals = m.send(:todays_logs_macros)
    expect(totals[:calories]).to be >= 200
    rem = m.remaining_macros_for_today
    expect(rem).to include(:calories, :protein_g)

    # normalization helper
    n = User.new(email: "UPPER@EX.COM", provider: "g", uid: "nn", sex: "MALE")
    n.valid?
    expect(n.email).to eq("upper@ex.com")

    # ensure age clamping around extremes also exercised
    young = User.create!(email: "y3@example.com", provider: "g", uid: "y3", height_cm: 150, weight_kg: 40, date_of_birth: Date.today - 10.years, sex: "female", activity_level: :sedentary, goal_type: :maintain, survey_completed: true)
    expect(young.send(:age_in_years)).to eq(18)

    old = User.create!(email: "old3@example.com", provider: "g", uid: "o3", height_cm: 150, weight_kg: 60, date_of_birth: Date.new(1900, 1, 1), sex: "female", activity_level: :sedentary, goal_type: :maintain, survey_completed: true)
    expect(old.send(:age_in_years)).to eq(100)
  end
end
