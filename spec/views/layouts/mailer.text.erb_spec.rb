require 'rails_helper'

RSpec.describe 'layouts/mailer.text.erb', type: :view do
  it 'layout mailer text file exists' do
    path = Rails.root.join('app', 'views', 'layouts', 'mailer.text.erb')
    expect(File).to exist(path)
  end
end
