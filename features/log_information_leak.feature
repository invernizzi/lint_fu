Feature: log information leak
  Scenario: true positives
    Given a simple Rails app
    And a Users controller defined by
    """
    logger.info("I like #{params[:password]}")
    logger.info("These are great: " + params[:secret])
    """
    When I run a scan
    Then the scan should contain 2 instances of LogInformationLeak

  Scenario: true negatives
    Given a simple Rails app
    And a Users controller defined by
    """
    logger.info("This is incredibly awesome! Yay!")
    logger.info("These are great: " + 7)
    logger.error "#{e.class}: #{e.message}\n\t#{e.backtrace[0]}"
    """
    When I run a scan
    Then the scan should contain no issues
