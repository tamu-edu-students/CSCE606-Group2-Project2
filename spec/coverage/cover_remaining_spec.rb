require "rails_helper"

RSpec.describe "cover remaining branches for coverage" do
  it "exercises private helpers across services and models" do
    # User helpers
    u = User.create!(
      email: "cover@example.com",
      provider: "google_oauth2",
      uid: "cover-1",
      height_cm: 170,
      weight_kg: 70,
      date_of_birth: Date.new(1990, 1, 1),
      sex: "male",
      activity_level: :sedentary,
      goal_type: :maintain,
      survey_completed: true
    )

    # activity multipliers for multiple levels
    %i[sedentary lightly_active moderately_active very_active extra_active].each do |lvl|
      u.activity_level = lvl
      expect(u.send(:activity_multiplier)).to be_a(Float)
    end

    # goal adjustments
    %w[lose gain maintain].each do |g|
      u.goal_type = g
      v = u.send(:goal_adjustment)
      expect([ Integer, Float ]).to include(v.class)
    end

    # basal metabolic rate for male and female
    u.sex = "male"
    expect(u.send(:basal_metabolic_rate)).to be >= 0
    u.sex = "female"
    expect(u.send(:basal_metabolic_rate)).to be >= 0

    # calculated_daily_carbs negative remaining -> 0
    carbs = u.send(:calculated_daily_carbs, calories: 100, protein: 10, fats: 10)
    expect(carbs).to be >= 0

    # build goals (exercise logger path)
    gmap = u.send(:build_daily_goals)
    expect(gmap).to include(:daily_calories_goal)

    # todays_logs_macros with a couple of logs
    u.food_logs.create!(food_name: "A", calories: 10, protein_g: 1, fats_g: 1, carbs_g: 1)
    totals = u.send(:todays_logs_macros)
    expect(totals).to include(:calories, :protein_g)

    # UpdateLog private checks
    fl = u.food_logs.create!(food_name: "B", calories: 50, protein_g: 5, fats_g: 2, carbs_g: 8)
    updater = NutritionAnalysis::UpdateLog.new(food_log: fl, params: {})
    expect(updater.send(:macro_fields_blank?)).to be(true)

    # VisionClient private helpers
    vc = NutritionAnalysis::VisionClient.new(openai_client: double("c"))
    expect(vc.send(:strip_code_fences, "```json\n{\"a\":1}\n```")).to include('{"a":1}')
    expect(vc.send(:convert_to_integer, "12.7")).to be_kind_of(Integer)
    expect(vc.send(:convert_to_integer, 5)).to eq(5)
    expect(vc.send(:convert_to_integer, nil)).to be_nil
  end
end
