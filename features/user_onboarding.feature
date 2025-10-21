Feature: User onboarding survey
  As a new user logging in with Google
  I want to complete the nutrition survey
  So that my dashboard shows personalized macro targets

  Background:
    Given OmniAuth is in test mode

  Scenario: Completing the onboarding survey
    When I sign in with Google
    And I visit the onboarding survey
    And I submit valid profile information
    Then I should see my dashboard
    And I should see today's macro summary
