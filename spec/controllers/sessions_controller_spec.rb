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
end
