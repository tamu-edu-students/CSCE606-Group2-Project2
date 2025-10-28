Feature: Food log flow
  As a QA/Developer
  I want to create food log entries and see them on my dashboard
  So that calories left is updated and entries appear

  Background:
    Given OmniAuth is in test mode
    And I am signed in

  Scenario: Create Food Log
    When I visit my dashboard
    And I click "Add a food entry"
    And I fill in the new food form with name "Lunch" and calories 500
  And I submit the new food form
  And I visit my dashboard
  And the entry for "Lunch" should show 500 calories
    And the Calories left total decreases by 500
