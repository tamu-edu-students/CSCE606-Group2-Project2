require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "session-1",
      info: { email: "session@example.com" }
    )
  end

  it "creates a session from the OmniAuth callback" do
    get "/auth/google_oauth2/callback"

    expect(response).to redirect_to(new_onboarding_path)
    expect(session[:user_id]).to be_present
  end

  it "signs out" do
    sign_in_via_omniauth(User.create!(email: "signout@example.com", provider: "google_oauth2", uid: "signout"))
    delete sign_out_path

    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to be_nil
  end

  it "handles failure" do
    get "/auth/failure", params: { message: "denied" }
    expect(response).to redirect_to(root_path)
  end
end
