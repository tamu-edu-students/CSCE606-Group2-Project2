module RequestAuthHelpers
  def sign_in_via_omniauth(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: user.uid,
      info: { email: user.email }
    )

    get "/auth/google_oauth2/callback"
  end
end

RSpec.configure do |config|
  config.include RequestAuthHelpers, type: :request
end
