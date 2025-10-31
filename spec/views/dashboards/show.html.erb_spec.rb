require 'rails_helper'

RSpec.describe 'dashboards/show.html.erb', type: :view do
  it 'view file exists' do
    path = Rails.root.join('app', 'views', 'dashboards', 'show.html.erb')
    expect(File).to exist(path)
  end
end
