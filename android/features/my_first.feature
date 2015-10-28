Feature: Login feature

  Scenario: As a valid user I can log into my app
    Given  I am on "Log in" with Glow
    When I enter valid username and password
    Then Click log in
