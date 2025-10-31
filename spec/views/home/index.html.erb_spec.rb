require 'rails_helper'

RSpec.describe 'home/index.html.erb', type: :view do
  it 'view file exists' do
    path = Rails.root.join('app', 'views', 'home', 'index.html.erb')
    expect(File).to exist(path)
  end
end
