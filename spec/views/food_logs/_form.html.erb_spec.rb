require 'rails_helper'

RSpec.describe 'food_logs/_form.html.erb', type: :view do
  it 'partial file exists' do
    path = Rails.root.join('app', 'views', 'food_logs', '_form.html.erb')
    expect(File).to exist(path)
  end
end
