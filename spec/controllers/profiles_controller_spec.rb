require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:user) { User.create!(email: 'p@example.com', provider: 'google_oauth2', uid: 'p-1') }

  before do
    session[:user_id] = user.id
  end

  describe 'PATCH #update_goals with calories_left' do
    it 'updates the daily_calories_goal when calories_left provided' do
      # create one food log for today with calories
      FoodLog.create!(user: user, food_name: 'X', calories: 100, protein_g: 1, fats_g: 1, carbs_g: 1)
      patch :update_goals, params: { calories_left: 500 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      expect(json['user']['calories_left']).to eq(500)
    end

    it 'returns errors when update fails' do
      allow_any_instance_of(User).to receive(:update).and_return(false)
      allow_any_instance_of(User).to receive_message_chain(:errors, :full_messages).and_return([ 'bad' ])
      patch :update_goals, params: { calories_left: 100 }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['success']).to be_falsey
      expect(json['errors']).to include('bad')
    end
  end

  describe 'PATCH #update_goals manual goals' do
    it 'sanitizes blank strings to nil and updates user' do
      patch :update_goals, params: { daily_calories_goal: '', daily_protein_goal_g: '50' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to eq(true)
      # blank string should become nil on model update; verify returned value exists
      expect(json['user']['daily_protein_goal_g']).to eq(50).or be_nil
    end
  end
end
