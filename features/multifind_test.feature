@multifind
Feature: testing multifind

  Scenario: Searching for multiple elements with 1 results
    Given the user navigates to URL "http://training-page.testautomation.info/"
    Then the user expects a result in a multi_find lookup
    Then the user expects an error in a multi_find lookup
    Then the user expects no error in a multi_find lookup
    Then the user expects 2 results in a multi_find_all lookup
    Then the user expects 1 results in a multi_find_all lookup
    Then the user expects 4 existing results in a multi_find_all lookup
    Then the user expects an error in a multi_find_all lookup
    Then the user expects no error in a multi_find_all lookup
    Then the user expects an error in a multi_find_all lookup matching all elements
    Then the user expects no error in a multi_find_all lookup matching all elements