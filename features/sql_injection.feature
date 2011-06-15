Feature: SQL injection
  Scenario: true positives
    Given a simple Rails app
    And a Users controller defined by
    """
    @user = User.find(:select => "SELECT * from USERS WHERE id = #{params[:user][:id]}")
    @user = User.first(:conditions => "email = #{params[:email]}")
    @user = User.all(:order=>"#{params[:sort]} DESC")
    @user = User.find_or_initialize_by_email(:include => [ "#{table_name}.*, '?' as extra", extra_data ])
    @user = User.all(:join=>"#{params[:foo]}")
    @user = User.all(:from=>"#{select_from_table}")
    """
    When I run a scan
    Then the scan should contain 6 instances of SqlInjection

  Scenario: true negatives
    Given a simple Rails app
    And a Users controller defined by
    """
    @user = User.find(:select => "SELECT * FROM users")
    @user = User.first(:conditions => {:email=>params[:email]} )
    @user = User.all(:order=>params[:sort])
    @user = User.find_or_initialize_by_email(:include => [ "email, '?' as extra", extra_data ])
    @user = User.all(:join=>params[:foo])
    @user = User.all(:from=>select_from_table)
    """
    When I run a scan
    Then the scan should contain no issues
