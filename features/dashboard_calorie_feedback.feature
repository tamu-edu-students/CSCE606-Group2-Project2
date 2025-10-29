Feature: Dashboard calorie feedback
  As a user keeping track of my nutrition
  I want the dashboard to highlight when I am over my calorie limit
  So that I can quickly understand my progress for the day

  Background:
    Given I am signed in

  Scenario: Staying under the calorie goal
    When I visit my dashboard
    Then I should see calories left highlighted as positive
    And I should not see a calories over warning

  Scenario: Exceeding the calorie goal
    Given I have a food log entry named "Feast" with 2100 calories
    When I visit my dashboard
    Then I should see calories left highlighted as negative
    And I should see a calories over warning
