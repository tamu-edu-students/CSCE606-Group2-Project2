When('I click the {string} link in the navigation') do |label|
  within('header .nav-list') do
    click_link label
  end
end

Then('I should be on the food logs page') do
  expect(page.current_path).to eq(food_logs_path)
end

Given('I have logged food on three different days') do
  user = User.find_by!(email: 'cuke.user@example.com')

  # Create one entry for each of the last three days with distinct macro values
  [ 0, 1, 2 ].each_with_index do |offset, idx|
    t = Time.zone.now.beginning_of_day - offset.days + 12.hours
    user.food_logs.create!(
      food_name: "Meal #{idx + 1}",
      calories: 300 + (idx * 100),
      protein_g: 10 + (idx * 5),
      fats_g: 5 + (idx * 3),
      carbs_g: 20 + (idx * 7),
      created_at: t,
      updated_at: t
    )
  end
end

When('I view my food log history') do
  visit food_logs_path
end

Then('I should see date headings for the last three days') do
  dates = [ 0, 1, 2 ].map { |d| I18n.l((Time.zone.today - d.days), format: :long) }
  dates.each do |label|
    expect(page).to have_css('h2', text: label)
  end
end

Then('I should see sortable links for Date, Calories, Proteins, Fats, and Carbs') do
  within('main') do
    expect(page).to have_link('Date')
    expect(page).to have_link('Calories')
    expect(page).to have_link('Proteins')
    expect(page).to have_link('Fats')
    expect(page).to have_link('Carbs')
  end
end
