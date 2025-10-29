Feature: Cancelled Google sign-in
  As a user
  I want to be redirected back to the homepage when I cancel the Google sign-in flow
  So I don't see a confusing application error and can try signing in again

  Background:
    Given OmniAuth is in test mode

  Scenario: Canceling the Google OAuth flow redirects to the homepage with a friendly message
  Given OmniAuth will fail with invalid_credentials
  When I start the Google sign in flow
    Then I should be on the homepage
    And I should see the authentication cancellation message
