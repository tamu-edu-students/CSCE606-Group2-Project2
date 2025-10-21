require "rails_helper"

RSpec.describe "Dashboards", type: :request do
  let(:user) do
    User.create!(
      email: "dash@example.com",
      provider: "google_oauth2",
      uid: "dash-1",
      daily_calories_goal: 2000,
      daily_protein_goal_g: 150,
      daily_fats_goal_g: 70,
      daily_carbs_goal_g: 230,
      survey_completed: true
    )
  end

  it "requires authentication" do
    get dashboard_path
    expect(response).to redirect_to(root_path)
  end

  it "redirects to onboarding when survey is incomplete" do
    user.update!(survey_completed: false)
    sign_in_via_omniauth(user)
    get dashboard_path

    expect(response).to redirect_to(new_onboarding_path)
  end

  it "renders success with remaining macros" do
    user.food_logs.create!(food_name: "Lunch", calories: 500, protein_g: 25, fats_g: 20, carbs_g: 50)

    sign_in_via_omniauth(user)
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Today's goals")
    expect(response.body).to include("Calories left")
  end
end
