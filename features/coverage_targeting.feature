Feature: Coverage targeting for MeasurementParamsNormalizer and OnboardingController
  These scenarios call specific code paths to increase coverage on both classes.

  Scenario: MeasurementParamsNormalizer - parse decimal-feet and inch formats
    When I normalize measurement params with system "imperial", height "5.5", weight "150lbs"
    Then the normalized height_cm should be "168"
    And the normalized weight_kg should be "68.0"

  Scenario: MeasurementParamsNormalizer - parse double-quote and in notation
    When I normalize measurement params with system "imperial", height "71in", weight "150"
    Then the normalized height_cm should be "180"
    And the normalized weight_kg should be "68.0"

  Scenario: MeasurementParamsNormalizer - invalid number returns nil
    When I normalize measurement params with system "imperial", height "abc", weight "xyz"
    Then the normalized height_cm should be "nil"
    And the normalized weight_kg should be "nil"

  Scenario: OnboardingController - raw params as ActionController::Parameters
    Given OmniAuth is in test mode
    When I sign in with Google
    And I call set_measurement_context with parameters measurement_system "metric"
    Then the form measurement_system should be "metric"

  Scenario: OnboardingController - new path shows update notice when survey completed
    Given OmniAuth is in test mode
    When I sign in with Google
    And my survey is already completed
    And I visit the onboarding survey
    Then I should see the notice about updating my profile

