Feature: Profile submission triggers calculation
  As a new user
  I want my profile data to trigger automatic calorie and macro calculations
  So that I receive personalized nutrition goals

  Background:
    Given OmniAuth is in test mode

  Scenario: Data Saved - calculated values populate the database
    Given I am a new user
    When I sign in with Google
    And I visit the onboarding survey
    And I fill in my profile with:
      | field          | value          |
      | Sex            | Male           |
      | Date of birth  | 1990-01-01     |
      | Height         | 180            |
      | Weight         | 80             |
      | Activity level | Moderately active |
      | Goal           | Maintain       |
    And I submit the profile form
    Then my user record should have calculated nutrition goals
    And the daily_calories_goal should be between 2400 and 2800
    And the daily_protein_goal_g should be between 140 and 150
    And the daily_fats_goal_g should be between 60 and 70
    And the daily_carbs_goal_g should be greater than 0

  Scenario: Calculation uses Mifflin-St Jeor formula
    Given I am a new user
    When I sign in with Google
    And I complete the profile with male, age 30, height 180cm, weight 80kg, moderately active, maintain goal
    Then the BMR calculation should use the formula "10 × 80 + 6.25 × 180 − 5 × 30 + 5"
    And the TDEE should be BMR multiplied by 1.55
    And the final daily_calories_goal should be TDEE with goal adjustment
