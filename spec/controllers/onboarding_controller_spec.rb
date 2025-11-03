require 'rails_helper'

RSpec.describe OnboardingController, type: :controller do
  let(:user) { User.create!(email: 'o@example.com', provider: 'google_oauth2', uid: 'o-1') }

  before do
    session[:user_id] = user.id
  end

  describe 'POST #create failure path' do
    it 'renders new with alert when complete_survey! returns false' do
      allow_any_instance_of(User).to receive(:complete_survey!).and_return(false)
      post :create, params: { user: { username: 'x' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(flash.now[:alert]).to be_present
    end

    it 'handles RecordInvalid by rendering new with alert' do
      allow_any_instance_of(User).to receive(:complete_survey!).and_raise(ActiveRecord::RecordInvalid.new(user))
      post :create, params: { user: { username: 'x' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'measurement context and defaults' do
    it 'accepts a Hash in set_measurement_context and applies imperial defaults' do
  user.update!(height_cm: 180, weight_kg: 75)
  # ensure controller has @user set (set_user before_action normally does this)
  controller.instance_variable_set(:@user, user)
  # directly invoke the private helper with a Hash to exercise the Hash branch
  controller.send(:set_measurement_context, { 'measurement_system' => 'imperial' })
      # defaults should be applied
      form = controller.instance_variable_get(:@form_params)
      expect(form['measurement_system']).to eq('imperial')
      # default inputs should be present and reflect imperial conversion
      expect(controller.send(:default_height_input)).to be_a(String)
      expect(controller.send(:default_weight_input)).to be_a(String)
    end
  end
end
