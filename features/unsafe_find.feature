Feature: unsafe find
  Scenario: true positives
    Given a simple Rails app
    And a Users controller defined by
    """
    @user = User.find(params[:user])
    @user = User.first(params[:user])
    @user = User.all(params[:user])
    @user = User.find_or_initialize_by_email(params[:user][:email])
    @user = User.find_or_initialize_by_company_id(params[:user][:company][:id])
    @user = User.verified.find_by_email(params[:user][:email])
    """
    When I run a scan
    Then the scan should contain 6 instances of UnsafeFind

  Scenario: true negatives
    Given a simple Rails app
    And a Users controller defined by
    """
    @user = current_user
    @user = User.find(5)
    @user = User.find_by_email('admin@example.com')
    @user = User.first(:conditions=>{:email=>'admin@example.com'})
    @user = User.all(:conditions=>['age < ?', 5])
    @user = User.first(:conditions=>{:company_id=>current_user.company})
    @company = Company.first(:conditions=>{:owner_id=>current_user.id})
    @outside_users = User.find_outside_of_company(current_user.company)
    """
    When I run a scan
    Then the scan should contain no issues

  Scenario: empty app
    Given a simple Rails app
    When I run a scan
    Then the scan should contain no issues
