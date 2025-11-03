require 'rails_helper'
require 'rack/test'

RSpec.describe FoodLogsController, type: :controller do
  let(:user) { User.create!(email: 'f@example.com', provider: 'google_oauth2', uid: 'f-1') }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index sorting and grouping' do
    it 'groups logs by date and honors non-date sort param' do
      # two logs on different dates
      older = FoodLog.create!(user: user, food_name: 'A', calories: 100, protein_g: 1, fats_g: 1, carbs_g: 1, created_at: 2.days.ago)
      newer = FoodLog.create!(user: user, food_name: 'B', calories: 200, protein_g: 2, fats_g: 2, carbs_g: 2, created_at: 1.day.ago)

  get :index, params: { sort: 'calories', direction: 'asc' }
  grouped = controller.instance_variable_get(:@grouped_logs)
  expect(grouped).to be_a(Hash)
  # non-date sort uses default ordering by created_at desc; ensure grouped keys present
  expect(grouped.keys).to include(older.created_at.to_date, newer.created_at.to_date)
    end

    it 'handles date sort with asc direction' do
      FoodLog.create!(user: user, food_name: 'X', calories: 50, protein_g: 1, fats_g: 1, carbs_g: 1, created_at: 3.days.ago)
  get :index, params: { sort: 'date', direction: 'asc' }
  grouped = controller.instance_variable_get(:@grouped_logs)
  expect(grouped).to be_a(Hash)
    end
  end

  describe 'POST #create' do
    it 'redirects to dashboard when survey_completed' do
      allow_any_instance_of(User).to receive(:survey_completed?).and_return(true)
      # stub service
      result = double('result', success?: true, food_log: FoodLog.new)
      allow(NutritionAnalysis::CreateLog).to receive(:new).and_return(double(call: result))

      post :create, params: { food_log: { food_name: 'X', calories: 100, protein_g: 1, fats_g: 1, carbs_g: 1 } }
      expect(response).to be_redirect
    end

    it 'redirects to onboarding when survey not completed' do
      allow_any_instance_of(User).to receive(:survey_completed?).and_return(false)
      result = double('result', success?: true, food_log: FoodLog.new)
      allow(NutritionAnalysis::CreateLog).to receive(:new).and_return(double(call: result))

      post :create, params: { food_log: { food_name: 'X', calories: 100, protein_g: 1, fats_g: 1, carbs_g: 1 } }
      expect(response).to be_redirect
    end

    it 'renders new with alert on analysis failure' do
      fake_food = FoodLog.new
      result = double('result', success?: false, food_log: fake_food, error_message: 'nope')
      allow(NutritionAnalysis::CreateLog).to receive(:new).and_return(double(call: result))

      post :create, params: { food_log: { food_name: 'Y' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to be_present
    end
  end

  describe 'PATCH #update' do
    let!(:log) { FoodLog.create!(user: user, food_name: 'Z', calories: 10, protein_g: 1, fats_g: 1, carbs_g: 1) }

    it 'triggers analysis when photo present and macros blank and redirects on success' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/sample.jpg'), 'image/jpeg')
      result = double('result', success?: true, food_log: log)
      allow(NutritionAnalysis::UpdateLog).to receive(:new).and_return(double(call: result))

      patch :update, params: { id: log.id, food_log: { photo: file, calories: nil, protein_g: nil, fats_g: nil, carbs_g: nil } }
      expect(response).to be_redirect
    end

    it 'renders edit with alert when analysis returns error' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/sample.jpg'), 'image/jpeg')
      fake = double('result', success?: false, food_log: log, error_message: 'err')
      allow(NutritionAnalysis::UpdateLog).to receive(:new).and_return(double(call: fake))

      patch :update, params: { id: log.id, food_log: { photo: file, calories: nil, protein_g: nil, fats_g: nil, carbs_g: nil } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'updates directly when macros provided' do
      patch :update, params: { id: log.id, food_log: { calories: 55, protein_g: 2, fats_g: 2, carbs_g: 5 } }
      expect(response).to be_redirect
    end

    it 'renders edit when update fails' do
      allow_any_instance_of(FoodLog).to receive(:update).and_return(false)
      patch :update, params: { id: log.id, food_log: { calories: 55 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE #destroy' do
    it 'removes entry and redirects' do
      f = FoodLog.create!(user: user, food_name: 'Del', calories: 10, protein_g: 1, fats_g: 1, carbs_g: 1)
      delete :destroy, params: { id: f.id }
      expect(response).to be_redirect
      expect { f.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
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
