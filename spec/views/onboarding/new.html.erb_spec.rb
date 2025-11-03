require 'rails_helper'

RSpec.describe 'onboarding/new.html.erb', type: :view do
  it 'view file exists' do
    path = Rails.root.join('app', 'views', 'onboarding', 'new.html.erb')
    expect(File).to exist(path)
  end
end
