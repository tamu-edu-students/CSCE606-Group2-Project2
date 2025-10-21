RSpec.configure do |config|
  config.before(:suite) do
    OmniAuth.config.test_mode = true
  end

  config.before do
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '12345',
      info: {
        email: 'spec-user@example.com'
      }
    )
  end

  config.after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
