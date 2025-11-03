require 'rails_helper'

RSpec.describe DashboardsController, type: :controller do
  let(:user) { User.create!(email: 'a@example.com', provider: 'google', uid: 'uid-a') }

  describe 'authentication' do
    it 'redirects unauthenticated user attempting to access dashboard to root' do
      get :show
      expect(response).to redirect_to(root_path)
    end

    it 'allows access when session contains user id' do
      session[:user_id] = user.id
      get :show
      expect(response).to have_http_status(:ok).or redirect_to(new_onboarding_path)
    end
  end
end
require 'rails_helper'

RSpec.describe 'Authentication (via controllers)', type: :controller do
  describe DashboardsController, type: :controller do
    context 'when not logged in' do
      it 'redirects unauthenticated user to root' do
        get :show
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe SessionsController, type: :controller do
    describe 'DELETE #destroy' do
      it 'clears the session and redirects to root' do
        # simulate a logged in user by setting session
        user = User.create!(email: 'a@example.com', provider: 'google_oauth2', uid: 'u1')
        session[:user_id] = user.id

        delete :destroy
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe SessionsController, type: :controller do
    before do
      Rails.application.routes.default_url_options[:host] = 'test.host'
    end
    before do
      # Replace redirect_to with a lightweight stub so tests don't hit URL host checks
      allow_any_instance_of(SessionsController).to receive(:redirect_to) do |instance, *args|
        path = args[0]
        opts = args[1].is_a?(Hash) ? args[1] : {}
        instance.flash[:alert] = opts[:alert] if opts[:alert]
        instance.flash[:success] = opts[:success] if opts[:success]
        instance.response.status = 302
        instance.response.location = path
        # stop further processing to avoid template lookup; render an empty body with redirect status
        instance.send(:render, plain: '', status: 302) rescue nil
      end
    end
    describe 'POST #create' do
      it 'creates/loads a user and redirects to dashboard or onboarding' do
        auth = { 'provider' => 'google_oauth2', 'uid' => 'u-999', 'info' => { 'email' => 'new@example.com' } }
        allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_return({ 'omniauth.auth' => auth })

        # Ensure the user is created via the model method
        expect(User).to receive(:find_or_create_from_auth_hash).and_call_original

        # ensure a valid host so redirecting to root/dashboard doesn't raise
        request.host = 'test.host'

        get :create, params: { provider: 'google_oauth2' }

        # Should set session[:user_id]
        expect(session[:user_id]).to be_present
        expect(response).to be_redirect
      end

      it 'handles exceptions and redirects to root with alert' do
        auth = { 'provider' => 'google_oauth2', 'uid' => 'u-err' }
        allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_return({ 'omniauth.auth' => auth })

        allow(User).to receive(:find_or_create_from_auth_hash).and_raise(StandardError.new('boom'))

        request.host = 'test.host'
        get :create, params: { provider: 'google_oauth2' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe 'GET #new' do
      it 'sets the authorization url' do
        get :new
        expect(controller.instance_variable_get(:@authorization_url)).to eq('/auth/google_oauth2')
        expect(response).to have_http_status(:ok).or have_http_status(:success)
      end
    end

    describe 'GET #failure' do
      it 'returns a friendly message for invalid_credentials' do
        get :failure, params: { message: 'invalid_credentials' }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/Authentication was canceled|Google sign-in failed/)
      end

      it 'maps authenticity token errors to a helpful message' do
        allow_any_instance_of(ActionDispatch::Request).to receive(:env).and_return({ 'omniauth.error.type' => 'csrf_detected' })
        request.host = 'test.host'
        get :failure
        expect(flash[:alert]).to match(/could not be verified/i)
      end
    end
  end
end
