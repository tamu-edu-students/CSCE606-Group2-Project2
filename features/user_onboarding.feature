Feature: User Onboarding Flow
  As a new user
  I want to complete the registration and onboarding process
  So that I can access my personalized dashboard after sign-up

  Background:
    Given the application is running

  @happy_path
  Scenario: Successful user sign-up
    Given I am on the registration page
    When I fill in "Email" with "newuser@example.com"
    And I fill in "Password" with "securePassword123"
    And I fill in "Password confirmation" with "securePassword123"
    And I click "Sign up"
    Then I should see "Please verify your email to continue"

  @negative_path
  Scenario: Invalid sign-up attempt
    Given I am on the registration page
    When I fill in "Email" with ""
    And I click "Sign up"
    Then I should see "Email can't be blank"

  @verification
  Scenario: Email verification
    Given I have received a verification email
    When I click the verification link
    Then my account should be activated
    And I should see "Your email has been confirmed"

  @onboarding
  Scenario: Complete onboarding setup
    Given my email is verified
    When I fill in my profile details
    And I click "Finish Setup"
    Then I should see "Welcome to your dashboard"

  @return_user
  Scenario: Returning user login
    Given I am a verified and onboarded user
    When I log in with valid credentials
    Then I should be redirected to my dashboard
