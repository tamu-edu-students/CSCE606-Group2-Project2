Feature: Session and profile flow
  As a QA/Developer
  I want to verify sign in, onboarding, and sign out flows

  Background:
    Given OmniAuth is in test mode

  Scenario: New User Onboarding
    Given I am a new user on the homepage
    When I click "Sign in with Google" and authenticate
    Then I should be on the Complete Your Profile page
  When I fill in my username "cukeuser", height "170" and weight "70"
  And I click the "Calculate my goals" button
    Then I should see my dashboard

  Scenario: Sign Out
    Given I am signed in
    When I click the "Sign out" button
    Then I should see "Signed out successfully"
  And I should see "Diet Tracker"
