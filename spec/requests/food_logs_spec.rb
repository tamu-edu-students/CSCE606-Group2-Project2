require "rails_helper"

RSpec.describe "FoodLogs", type: :request do
  let(:user) do
    User.create!(
      email: "logs@example.com",
      provider: "google_oauth2",
      uid: "logs-1",
      survey_completed: true,
      daily_calories_goal: 2000,
      daily_protein_goal_g: 120,
      daily_fats_goal_g: 60,
      daily_carbs_goal_g: 200
    )
  end

  describe "GET /food_logs/new" do
    it "requires login" do
      get new_food_log_path
      expect(response).to redirect_to(root_path)
    end

    it "renders the form" do
      sign_in_via_omniauth(user)
      get new_food_log_path
      expect(response.body).to include("Log a meal")
    end
  end

  describe "POST /food_logs" do
    it "creates a log when macros provided" do
      expect do
        sign_in_via_omniauth(user)
        post food_logs_path,
             params: { food_log: { food_name: "Toast", calories: 150, protein_g: 5, fats_g: 3, carbs_g: 25 } }
      end.to change(FoodLog, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "renders errors when analysis fails" do
      failure = NutritionAnalysis::Result.new(food_log: FoodLog.new(user:), error_message: "API down")
      allow(NutritionAnalysis::CreateLog).to receive(:new).and_return(double(call: failure))

      sign_in_via_omniauth(user)
      post food_logs_path,
           params: { food_log: { food_name: "Mystery" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("API down")
    end
  end

  describe "GET /food_logs/:id/edit" do
    it "requires login" do
      entry = user.food_logs.create!(food_name: "Apple", calories: 100, protein_g: 0, fats_g: 0, carbs_g: 25)

      get edit_food_log_path(entry)
      expect(response).to redirect_to(root_path)
    end

    it "renders the edit form with existing values" do
      entry = user.food_logs.create!(food_name: "Apple", calories: 100, protein_g: 0, fats_g: 0, carbs_g: 25)

      sign_in_via_omniauth(user)
      get edit_food_log_path(entry)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit food entry")
      expect(response.body).to include('value="Apple"')
      expect(response.body).to include('value="100"')
    end
  end

  describe "PATCH /food_logs/:id" do
    it "updates a log and redirects to the dashboard" do
      entry = user.food_logs.create!(food_name: "Apple", calories: 100, protein_g: 1, fats_g: 0, carbs_g: 25)

      sign_in_via_omniauth(user)
      patch food_log_path(entry),
            params: { food_log: { calories: 150, food_name: "Green Apple", protein_g: 1, fats_g: 0, carbs_g: 25 } }

      expect(response).to redirect_to(dashboard_path)
      expect(entry.reload.calories).to eq(150)
      expect(entry.food_name).to eq("Green Apple")
    end

    it "renders errors when validation fails" do
      entry = user.food_logs.create!(food_name: "Apple", calories: 100, protein_g: 1, fats_g: 0, carbs_g: 25)

      sign_in_via_omniauth(user)
      patch food_log_path(entry),
            params: { food_log: { food_name: "", calories: 90, protein_g: 1, fats_g: 0, carbs_g: 25 } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("We couldn&#39;t update this food entry.")
      expect(entry.reload.food_name).to eq("Apple")
    end
  end

  describe "DELETE /food_logs/:id" do
    it "removes a log" do
      entry = user.food_logs.create!(food_name: "Coffee", calories: 5, protein_g: 0, fats_g: 0, carbs_g: 1)

      expect do
        sign_in_via_omniauth(user)
        delete food_log_path(entry)
      end.to change(FoodLog, :count).by(-1)

      expect(response).to redirect_to(dashboard_path)
    end
  end
end
