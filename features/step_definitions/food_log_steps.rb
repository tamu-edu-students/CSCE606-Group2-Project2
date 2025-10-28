Given('I am signed in') do
  # Ensure OmniAuth is in test mode with a mock user
  if defined?(OmniAuth)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] ||= OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: '123545',
      info: { email: 'cuke.user@example.com', name: 'Cuke User' },
      credentials: { token: 'mock_token', refresh_token: 'mock_refresh' }
    )
  end

  visit '/auth/google_oauth2'
  sleep 0.1

  user = User.find_by(email: 'cuke.user@example.com')
  if user
    user.update!(survey_completed: true,
                 daily_calories_goal: 2000,
                 daily_protein_goal_g: 100,
                 daily_fats_goal_g: 70,
                 daily_carbs_goal_g: 250)
  end
end

Given('I have a food log entry named {string} with {int} calories') do |name, calories|
  user = User.find_by!(email: 'cuke.user@example.com')
  user.food_logs.create!(
    food_name: name,
    calories: calories,
    protein_g: 1,
    fats_g: 1,
    carbs_g: 1
  )
end

When('I visit my dashboard') do
  visit dashboard_path
end

Then('I should see an edit link for {string}') do |name|
  within('.logs') do
    row = find('tr', text: name)
    expect(row).to have_link('Edit')
  end
end

When('I click edit for {string}') do |name|
  within('.logs') do
    row = find('tr', text: name)
    row.click_link('Edit')
  end
end

Then('I should see the edit form prefilled with name {string} and calories {int}') do |name, calories|
  expect(page).to have_content('Edit food entry')
  expect(find_field('Food name').value).to eq(name)
  expect(find_field('Calories').value).to eq(calories.to_s)
end

When('I change the calories to {int}') do |calories|
  fill_in 'Calories', with: calories
end

When('I submit the food log form') do
  click_button 'Save changes'
end

Then('the entry for {string} should show {int} calories') do |name, calories|
  within('.logs') do
    row = find('tr', text: name)
    expect(row).to have_content(calories.to_s)
  end
end

Then('I should be on the dashboard') do
  expect(page.current_path).to eq(dashboard_path)
end
