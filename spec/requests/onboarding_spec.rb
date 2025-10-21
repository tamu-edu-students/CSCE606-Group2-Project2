require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) do
    User.create!(
      email: "onboard@example.com",
      provider: "google_oauth2",
      uid: "onboard-1"
    )
  end

  describe "GET /onboarding/new" do
    it "redirects anonymous users" do
      get new_onboarding_path
      expect(response).to redirect_to(root_path)
    end

    it "renders success for signed-in users" do
      sign_in_via_omniauth(user)
      get new_onboarding_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tell us about you")
    end

    it "allows retaking the survey when already completed" do
      user.update!(
        survey_completed: true,
        height_cm: 175,
        weight_kg: 70,
        daily_calories_goal: 2000,
        daily_protein_goal_g: 120,
        daily_fats_goal_g: 60,
        daily_carbs_goal_g: 220
      )

      sign_in_via_omniauth(user)
      get new_onboarding_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tell us about you")
      expect(flash[:notice]).to eq("Updating your profile will recalculate today's goals.")
    end
  end

  describe "POST /onboarding" do
    let(:params) do
      {
        user: {
          sex: "female",
          date_of_birth: "1995-06-15",
          height_input: 165,
          weight_input: 60,
          activity_level: "lightly_active",
          goal_type: "maintain",
          measurement_system: "metric"
        }
      }
    end

    it "calculates goals and redirects" do
      sign_in_via_omniauth(user)
      post onboarding_path, params: params

      expect(response).to redirect_to(dashboard_path)
      user.reload
      expect(user).to be_survey_completed
      expect(user.daily_calories_goal).to be_positive
    end

    it "accepts imperial height and weight and converts them" do
      params[:user][:height_input] = "5'8\""
      params[:user][:weight_input] = 165
      params[:user][:measurement_system] = "imperial"

      sign_in_via_omniauth(user)
      post onboarding_path, params: params

      expect(response).to redirect_to(dashboard_path)
      user.reload
      expect(user.height_cm).to eq(173)
      expect(user.weight_kg).to be_within(0.1).of(74.8)
    end

    it "renders errors for invalid submissions" do
      sign_in_via_omniauth(user)
      post onboarding_path,
           params: {
             user: {
               sex: "female",
               date_of_birth: "1995-06-15",
               height_input: "-10",
               weight_input: "-5",
               activity_level: "lightly_active",
               goal_type: "maintain",
               measurement_system: "metric"
             }
           }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please correct the highlighted errors")
    end
  end
end
