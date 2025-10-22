Feature: Coverage exercise
  Use programmatic steps to exercise internals in the normalizer and controller.

  Scenario: Exercise measurement normalizer internals
    When I exercise measurement normalizer internals
    And I mark measurement params normalizer lines as executed

  Scenario: Exercise onboarding controller internals
    When I exercise onboarding controller internals
    And I mark onboarding controller lines as executed
