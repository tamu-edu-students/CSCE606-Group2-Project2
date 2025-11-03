require 'rails_helper'

RSpec.describe 'food_logs/index.html.erb', type: :view do
  it 'view file exists' do
    path = Rails.root.join('app', 'views', 'food_logs', 'index.html.erb')
    expect(File).to exist(path)
  end
end
