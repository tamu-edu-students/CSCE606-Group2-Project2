Feature: Onboarding imperial defaults coverage
  Ensure imperial branches in OnboardingController are exercised and formatted correctly.

  Background:
    Given OmniAuth is in test mode

  Scenario: imperial default height and weight inputs shown when user has metric stored
    When I sign in with Google
    And my user has height 180 cm and weight 68.0 kg
    And I visit the onboarding survey with measurement system "imperial"
    Then the height input should match "5'11\"|71"
    And the weight input should contain "149.9"

  Scenario: set_measurement_context accepts ActionController::Parameters with imperial
    When I sign in with Google
    And I visit the onboarding survey with measurement system "imperial"
    Then the form measurement_system should be "imperial"

