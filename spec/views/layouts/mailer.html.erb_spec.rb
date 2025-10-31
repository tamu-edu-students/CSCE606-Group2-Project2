require 'rails_helper'

RSpec.describe 'layouts/mailer.html.erb', type: :view do
  it 'layout mailer file exists' do
    path = Rails.root.join('app', 'views', 'layouts', 'mailer.html.erb')
    expect(File).to exist(path)
  end
end
