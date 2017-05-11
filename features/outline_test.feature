Feature: This is line 1

  @outline
  Scenario Outline: This is line 4
    Given this step is line 5
    When when this step uses "<outline-item>" this should be line 6
    Then this is line 7
    Examples:
      | outline-item    |
      | example-line-10 |

  @regular
  Scenario: This is line 13
    Given this step is line 14
    When when this step uses "no-outline" this should be line 15
    Then this is line 16