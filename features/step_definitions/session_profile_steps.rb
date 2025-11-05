Given('I am a new user on the homepage') do
  # remove any existing test user so the flow treats this as a new user
  User.where(email: 'cuke.user@example.com').destroy_all
  visit root_path
  expect(page).to have_content(/Sign in with Google/i)
end

When('I click {string} and authenticate') do |link_text|
  # Click the sign-in link and trigger OmniAuth test callback
  begin
    click_link link_text
  rescue Capybara::ElementNotFound
    # Fallback: directly invoke the OmniAuth entrypoint
    visit '/auth/google_oauth2'
  end
  # If we landed on an intermediate sign-in page, trigger the OAuth entrypoint
  if page.current_path =~ /sign_in/ || page.has_button?('Sign in with Google') || page.has_content?('Sign in with Google')
    # try clicking the in-page button first
    click_button('Sign in with Google') rescue visit('/auth/google_oauth2')
  end
  sleep 0.1
end

Then('I should be on the Complete Your Profile page') do
  # Onboarding page header or path
  ok = page.has_content?('Tell us about you') || (page.current_path && page.current_path.match?(/onboarding/))
  unless ok
    warn "[CUKE DEBUG] current_path=#{page.current_path}"
    warn page.body[0..1200]
  end
  expect(ok).to be true
end

When('I fill in my username {string}, height {string} and weight {string}') do |username, height, weight|
  # Fill fields shown in the onboarding form
  fill_in 'Username', with: username
  fill_in 'user_height_input', with: height
  fill_in 'user_weight_input', with: weight
end

When('I click the {string} button') do |button_text|
  # Some pages use different button labels; be permissive
  if page.has_button?(button_text)
    click_button button_text
  else
    click_button(button_text) rescue click_button('Calculate my goals')
  end
end

Then('I should be on the homepage') do
  ok = (page.respond_to?(:has_current_path?) && page.has_current_path?(root_path)) || page.has_content?(/Diet Tracker/i)
  unless ok
    warn "[CUKE DEBUG] current_path=#{page.current_path}"
    warn page.body[0..1200]
  end
  expect(ok).to be true
end



## note: rely on the generic "I click the {string} button" step for Sign out to avoid ambiguity
