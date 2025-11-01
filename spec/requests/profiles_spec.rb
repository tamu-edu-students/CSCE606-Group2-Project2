require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) do
    User.create!(email: "profile@example.com", provider: "google_oauth2", uid: "p-1")
  end

  describe "PATCH /profile/goals" do
    it "updates manual goals for the current user" do
      sign_in_via_omniauth(user)

      patch "/profile/goals", params: { daily_calories_goal: 2500, daily_protein_goal_g: 120 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      user.reload
      expect(user.daily_calories_goal).to eq(2500)
      expect(user.daily_protein_goal_g).to eq(120)
    end

    it "converts calories_left into a new daily_calories_goal" do
      # create a food log for today consuming 400 calories
      FoodLog.create!(user:, food_name: "Snack", calories: 400, protein_g: 2, fats_g: 1, carbs_g: 80)

      sign_in_via_omniauth(user)

      patch "/profile/goals", params: { calories_left: 600 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      user.reload
      expect(user.daily_calories_goal).to eq(400 + 600)
      expect(json["user"]["calories_left"]).to eq(600)
    end

    it "returns errors for invalid manual goals" do
      sign_in_via_omniauth(user)

      patch "/profile/goals", params: { daily_calories_goal: -100 }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["success"]).to be false
      expect(json["errors"]).to be_an(Array)
    end
  end
end
