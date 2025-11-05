require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /' do
    it 'renders the home page with hero content when not signed in' do
      get root_path
      expect(response).to have_http_status(:ok)
  expect(response.body).to include('Diet Tracker')
      expect(response.body).to include('Sign in with Google')
    end
  end
end
