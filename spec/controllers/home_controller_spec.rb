require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    it 'redirects signed-in user to dashboard when survey completed' do
      user = User.create!(email: 'h@example.com', provider: 'google_oauth2', uid: 'h-1')
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow(user).to receive(:survey_completed?).and_return(true)

      get :index
      expect(response).to be_redirect
    end

    it 'redirects signed-in user to onboarding when survey incomplete' do
      user = User.create!(email: 'h2@example.com', provider: 'google_oauth2', uid: 'h-2')
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow(user).to receive(:survey_completed?).and_return(false)

      get :index
      expect(response).to be_redirect
    end
  end
end
