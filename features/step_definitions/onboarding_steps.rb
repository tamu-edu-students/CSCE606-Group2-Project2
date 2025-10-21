Given("OmniAuth is in test mode") do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
    provider: "google_oauth2",
    uid: "cucumber-user",
    info: { email: "cucumber@example.com" }
  )
end

When("I sign in with Google") do
  visit "/auth/google_oauth2"
end

When("I visit the onboarding survey") do
  visit new_onboarding_path
end

When("I submit valid profile information") do
  select "Male", from: "Sex"
  fill_in "Date of birth", with: "1990-01-01"
  fill_in "Height (cm)", with: 180
  fill_in "Weight (kg)", with: 80
  select "Lightly active", from: "Activity level"
  select "Maintain", from: "Goal"
  click_button "Calculate my goals"
end

Then("I should see my dashboard") do
  expect(page).to have_current_path(dashboard_path)
end

Then("I should see today's macro summary") do
  expect(page).to have_content("Today's goals")
  expect(page).to have_content("Calories left")
end
