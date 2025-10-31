require 'rails_helper'

RSpec.describe 'food_logs/new.html.erb', type: :view do
  it 'view file exists' do
    path = Rails.root.join('app', 'views', 'food_logs', 'new.html.erb')
    expect(File).to exist(path)
  end
end
