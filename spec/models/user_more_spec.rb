require "rails_helper"

RSpec.describe "user more coverage" do
  it "builds daily goals and logs info path" do
    u = User.create!(
      email: "more1@example.com",
      provider: "google_oauth2",
      uid: "more-1",
      height_cm: 180,
      weight_kg: 82,
      date_of_birth: Date.new(1990, 1, 1),
      sex: "male",
      activity_level: :very_active,
      goal_type: :gain,
      survey_completed: true
    )

    expect(Rails.logger).to receive(:info).at_least(:once)
    g = u.send(:build_daily_goals)
    expect(g).to include(:daily_calories_goal, :daily_protein_goal_g)
  end

  it "calculated_daily_carbs returns positive when remaining calories exist" do
    u = User.create!(email: "more2@example.com", provider: "g", uid: "m2", height_cm: 170, weight_kg: 70, date_of_birth: Date.new(1990, 1, 1), sex: "male", activity_level: :moderately_active, goal_type: :maintain, survey_completed: true)
    carbs = u.send(:calculated_daily_carbs, calories: 2000, protein: 100, fats: 50)
    expect(carbs).to be > 0
  end

  it "complete_survey! triggers calculate_goals! when manual goals absent" do
    u = User.create!(email: "more3@example.com", provider: "g", uid: "m3", height_cm: 170, weight_kg: 70, date_of_birth: Date.new(1990, 1, 1), sex: "male", activity_level: :moderately_active, goal_type: :maintain, survey_completed: false)
    expect_any_instance_of(User).to receive(:calculate_goals!).at_least(:once)
    u.complete_survey!(activity_level: :lightly_active)
  end

  it "recalculate_goals_if_needed triggers calculate_goals! when predicate true" do
    u = User.create!(email: "more4@example.com", provider: "g", uid: "m4", height_cm: 170, weight_kg: 70, date_of_birth: Date.new(1990, 1, 1), sex: "male", activity_level: :moderately_active, goal_type: :maintain, survey_completed: true)
    allow_any_instance_of(User).to receive(:needs_goal_recalculation?).and_return(true)
    expect_any_instance_of(User).to receive(:calculate_goals!).once
    u.update!(weight_kg: 71)
  end
end
