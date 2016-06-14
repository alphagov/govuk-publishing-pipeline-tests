Feature: Indexing links in search

  Scenario: New links get added
    When I create a draft content item
    Then it should not be in the live content store
    And it should be in the draft content store

    When we publish the item
    Then we should see it in the live content store

    When we send the document to search
    And we wait until the document is indexed

    When we create a topic to tag to
    And we tag our document to this topic
    Then both content stores have been updated with `organisations` tag
    And and the document is updated in search
