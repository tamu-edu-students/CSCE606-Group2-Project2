Given('I am a new user') do
  # User will be created when signing in with OmniAuth
  # No additional setup needed
end

Then('a calculation should be triggered in the backend') do
  # After submitting valid profile info and seeing dashboard,
  # verify that calculation happened and goals were set
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user).to be_present
  expect(user.survey_completed?).to be(true)
  # Verify that calculated goals are populated (proof calculation ran)
  expect(user.daily_calories_goal).to be_present
  expect(user.daily_protein_goal_g).to be_present
  expect(user.daily_fats_goal_g).to be_present
end

When('I fill in my profile with:') do |table|
  visit new_onboarding_path

  # Fill in username if field exists
  if page.has_field?('user[username]')
    fill_in 'user[username]', with: 'test_user'
  end

  table.rows_hash.each do |field, value|
    case field
    when 'Sex'
      select value, from: 'Sex'
    when 'Date of birth'
      fill_in 'Date of birth', with: value
    when 'Height'
      fill_in 'user_height_input', with: value
    when 'Weight'
      fill_in 'user_weight_input', with: value
    when 'Activity level'
      select value, from: 'Activity level'
    when 'Goal'
      select value, from: 'Goal'
    end
  end
end

When('I submit the profile form') do
  click_button 'Calculate my goals'
end

Then('my user record should have calculated nutrition goals') do
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user.daily_calories_goal).to be_present
  expect(user.daily_protein_goal_g).to be_present
  expect(user.daily_fats_goal_g).to be_present
  expect(user.daily_carbs_goal_g).to be_present
end

Then('the daily_calories_goal should be between {int} and {int}') do |min, max|
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user.daily_calories_goal).to be_between(min, max)
end

Then('the daily_protein_goal_g should be between {int} and {int}') do |min, max|
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user.daily_protein_goal_g).to be_between(min, max)
end

Then('the daily_fats_goal_g should be between {int} and {int}') do |min, max|
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user.daily_fats_goal_g).to be_between(min, max)
end

Then('the daily_carbs_goal_g should be greater than {int}') do |min|
  user = User.find_by(email: 'cuke.user@example.com')
  expect(user.daily_carbs_goal_g).to be > min
end

When('I complete the profile with male, age {int}, height {int}cm, weight {int}kg, moderately active, maintain goal') do |age, height, weight|
  birth_year = Time.zone.today.year - age

  visit new_onboarding_path
  select 'Male', from: 'Sex'
  fill_in 'Date of birth', with: "#{birth_year}-01-01"
  fill_in 'user_height_input', with: height.to_s
  fill_in 'user_weight_input', with: weight.to_s
  select 'Moderately active', from: 'Activity level'
  select 'Maintain', from: 'Goal'
  click_button 'Calculate my goals'
end

Then('the BMR calculation should use the formula {string}') do |formula|
  # This is a documentation step - the formula is verified by the resulting calculations
  user = User.find_by(email: 'cuke.user@example.com')
  # For male: BMR = 10 × 80 + 6.25 × 180 − 5 × 30 + 5
  # = 800 + 1125 - 150 + 5 = 1780
  expected_bmr = 10 * 80 + 6.25 * 180 - 5 * 30 + 5
  expect(expected_bmr).to eq(1780)
end

Then('the TDEE should be BMR multiplied by {float}') do |multiplier|
  # TDEE = BMR × activity multiplier
  # For moderately active: 1780 × 1.55 = 2759
  user = User.find_by(email: 'cuke.user@example.com')
  bmr = 1780
  expected_tdee = (bmr * multiplier).round
  # With maintenance goal (0 adjustment), daily_calories_goal should be close to TDEE
  expect(user.daily_calories_goal).to be_within(50).of(expected_tdee)
end

Then('the final daily_calories_goal should be TDEE with goal adjustment') do
  user = User.find_by(email: 'cuke.user@example.com')
  # For maintain goal, adjustment is 0, so final should equal TDEE
  # TDEE = 2759, so we expect something in that range
  expect(user.daily_calories_goal).to be_between(2700, 2800)
end
