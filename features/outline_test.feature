@outlinetest
Feature: This is line 2

  @outline
  Scenario Outline: This is line 5
    Given this step is line 6
    When when this step uses "<outline-item>" this should be line 7
    Then this is line 8
    Examples:
      | outline-item    |
      | example-line-11 |

  @regular
  Scenario: This is line 14
    Given this step is line 15
    When when this step uses "no-outline" this should be line 16
    Then this is line 17