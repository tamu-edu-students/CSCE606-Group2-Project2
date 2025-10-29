Then('I should see calories left highlighted as positive') do
  within('.summary-card') do
    expect(page).to have_css('.calories-left .value.value--positive')
    expect(page).not_to have_css('.calories-left .value.value--negative')
  end
end

Then('I should see calories left highlighted as negative') do
  within('.summary-card') do
    expect(page).to have_css('.calories-left .value.value--negative')
  end
end

Then('I should see a calories over warning') do
  within('.summary-card') do
    expect(page).to have_css('.calories-over-message', text: 'Calories Over')
  end
end

Then('I should not see a calories over warning') do
  within('.summary-card') do
    expect(page).not_to have_css('.calories-over-message')
  end
end
