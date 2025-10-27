require "omniauth"

client_id = ENV["GOOGLE_CLIENT_ID"]
client_secret = ENV["GOOGLE_CLIENT_SECRET"]

if client_id.present? && client_secret.present?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             client_id,
             client_secret,
             {
               scope: "userinfo.email,userinfo.profile",
               access_type: "offline",
               prompt: "select_account"
             }
  end
elsif Rails.env.test?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :google_oauth2,
             "test-client-id",
             "test-client-secret",
             {
               scope: "userinfo.email,userinfo.profile",
               access_type: "offline",
               prompt: "consent"
             }
  end
else
  Rails.logger.warn("Google OAuth env vars missing; OmniAuth provider not configured") if Rails.logger
end

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true


OmniAuth.config.on_failure = Proc.new do |env|
  SessionsController.action(:failure).call(env)
end
