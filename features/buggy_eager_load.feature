Feature: buggy eager load
  Scenario: true positives
    Given a simple Rails app
    And a Toy model defined by
    """
    acts_as_paranoid
    belongs_to :toy_bag
    """
    And a ToyBag model defined by
    """
    acts_as_paranoid
    belongs_to :user
    has_many :toys
    """
    And a ToyBags controller defined by
    """
    ToyBag.first(:include=>:toys, :conditions=>'toys.name IS NOT NULL')
    """
    When I run a scan
    Then the scan should contain an instance of BuggyEagerLoad

  Scenario: true negatives
    Given a simple Rails app
    And a Toy model defined by
    """
    acts_as_paranoid
    belongs_to :toy_bag
    """
    And a ToyBag model defined by
    """
    acts_as_paranoid
    belongs_to :user
    has_many :toys
    """
    And a ToyBags controller defined by
    """
    ToyBag.first(:include=>:toys, :conditions=>{:material=>'burlap'})
    """
    When I run a scan
    Then the scan should contain an instance of BuggyEagerLoad
