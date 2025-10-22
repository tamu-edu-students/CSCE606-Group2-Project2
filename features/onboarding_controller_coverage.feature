Feature: OnboardingController targeted coverage
  These scenarios exercise specific branches in OnboardingController using existing step helpers.

  Background:
    Given OmniAuth is in test mode

  Scenario: create returns true and redirects
    When I sign in with Google
    And I visit the onboarding survey
    And I submit valid profile information
    Then I should see my dashboard

  Scenario: create returns false and shows errors
    When I sign in with Google
    And I visit the onboarding survey
    And I submit invalid profile information
    Then I should see "Please correct the highlighted errors."

  Scenario: create raises RecordInvalid and shows errors
    When I sign in with Google
    And my complete_survey! will raise a RecordInvalid
    And I visit the onboarding survey
    And I submit valid profile information
    Then I should see "Please correct the highlighted errors."

  Scenario: set_measurement_context with raw Hash and imperial defaults
    When I sign in with Google
    And I call set_measurement_context with a raw Hash
    Then the form measurement_system should be "metric"

