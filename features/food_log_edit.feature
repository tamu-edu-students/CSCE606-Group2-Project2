Feature: Edit food logs
  As a user
  I want to update a food log entry
  So that I can correct mistakes after saving

  Background:
    Given OmniAuth is in test mode
    And I am signed in
    And I have a food log entry named "Apple" with 100 calories

  Scenario: Edit link is visible on the dashboard
    When I visit my dashboard
    Then I should see an edit link for "Apple"

  Scenario: Edit form is pre-filled
    When I visit my dashboard
    And I click edit for "Apple"
    Then I should see the edit form prefilled with name "Apple" and calories 100

  Scenario: Update a food log entry
    When I visit my dashboard
    And I click edit for "Apple"
    And I change the calories to 150
    And I submit the food log form
    Then I should be on the dashboard
    And the entry for "Apple" should show 150 calories
