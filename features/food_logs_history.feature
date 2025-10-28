Feature: View food log history
  As a user
  I want to view a history of my past food logs
  So that I can review my long-term progress and patterns

  Background:
    Given I am signed in

  Scenario: View Page
    When I click the "Food logs" link in the navigation
    Then I should be on the food logs page

  Scenario: Grouped Logs and Sortable Columns
    Given I have logged food on three different days
    When I view my food log history
    Then I should see date headings for the last three days
    And I should see sortable links for Date, Calories, Proteins, Fats, and Carbs
