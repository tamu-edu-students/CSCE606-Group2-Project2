require 'rails_helper'

RSpec.describe 'layouts/application.html.erb', type: :view do
  it 'layout file exists' do
    path = Rails.root.join('app', 'views', 'layouts', 'application.html.erb')
    expect(File).to exist(path)
  end
end
