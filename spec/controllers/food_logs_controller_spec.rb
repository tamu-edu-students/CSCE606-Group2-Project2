require 'rails_helper'

RSpec.describe FoodLogsController, type: :controller do
  let!(:user) { User.create!(email: 'creator@example.com', provider: 'google', uid: 'uid-creator') }

  describe 'authentication' do
    it 'redirects unauthenticated user creating food log to root' do
      post :create, params: { food_log: { food_name: 'Test', calories: 100, protein_g: 5, fats_g: 2, carbs_g: 10 } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'core logic' do
    before { session[:user_id] = user.id }

    it 'creates a new food log associated with current_user' do
      expect {
        post :create, params: { food_log: { food_name: 'Lunch', calories: 500, protein_g: 30, fats_g: 20, carbs_g: 50 } }
      }.to change { FoodLog.count }.by(1)

      log = FoodLog.order(:created_at).last
      expect(log.user_id).to eq(user.id)
    end

    it "prevents User A from destroying User B's food log" do
      other = User.create!(email: 'other@example.com', provider: 'google', uid: 'uid-other')
      log = other.food_logs.create!(food_name: 'Other', calories: 200, protein_g: 10, fats_g: 5, carbs_g: 20)

      session[:user_id] = user.id

      expect {
        delete :destroy, params: { id: log.id }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect(FoodLog.exists?(log.id)).to be true
    end
  end
end
require 'rails_helper'

RSpec.describe FoodLogsController, type: :controller do
  let!(:user) { User.create!(email: 'food@example.com', provider: 'google_oauth2', uid: 'food-1') }

  describe 'authentication and create' do
    context 'when not logged in' do
      it 'redirects to root when accessing new' do
        get :new
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when logged in' do
      before do
        session[:user_id] = user.id
      end

      it 'creates a new FoodLog associated with current_user' do
        expect {
          post :create, params: { food_log: { food_name: 'Apple', calories: 100, protein_g: 1, fats_g: 0, carbs_g: 25 } }
        }.to change { user.food_logs.count }.by(1)

        created = user.food_logs.order(created_at: :desc).first
        expect(created.food_name).to eq('Apple')
        expect(created.user_id).to eq(user.id)
      end
    end
  end
end
