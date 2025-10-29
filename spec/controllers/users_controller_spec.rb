require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let!(:user_a) { User.create!(email: 'a@example.com', provider: 'google', uid: 'uid-a') }
  let!(:user_b) { User.create!(email: 'b@example.com', provider: 'google', uid: 'uid-b') }

  describe 'authentication' do
    it 'redirects unauthenticated user trying to access profile update to root' do
      patch :update_goals, params: { daily_calories_goal: 2000 }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'authorization' do
    it "does not allow User A to affect User B's data via session spoofing" do
      # simulate sign in as user_a
      session[:user_id] = user_a.id

      # attempt to perform an action intended for current_user but pass params referencing user_b
      patch :update_goals, params: { id: user_b.id, daily_calories_goal: 1800 }

      # The controller operates on current_user; user_b should remain unchanged
      user_b.reload
      expect(user_b.daily_calories_goal).to be_nil.or be_zero
    end
    end
end
