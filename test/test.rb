require "helper"
require "omniauth-slack"

class StrategyTest < StrategyTestCase
  include OAuth2StrategyTests
end

class ClientTest < StrategyTestCase
  test "has correct Slack site" do
    assert_equal "https://slack.com", strategy.client.site
  end

  test "has correct authorize url" do
    assert_equal "/oauth/authorize", strategy.client.options[:authorize_url]
  end

  test "has correct token url" do
    assert_equal "/api/oauth.access", strategy.client.options[:token_url]
  end
end

class CallbackUrlTest < StrategyTestCase
  test "returns the default callback url" do
    url_base = "http://auth.request.com"
    @request.stubs(:url).returns("#{url_base}/some/page")
    strategy.stubs(:script_name).returns("") # as not to depend on Rack env
    assert_equal "#{url_base}/auth/slack/callback", strategy.callback_url
  end

  test "returns path from callback_path option" do
    @options = { :callback_path => "/auth/slack/done"}
    url_base = "http://auth.request.com"
    @request.stubs(:url).returns("#{url_base}/page/path")
    strategy.stubs(:script_name).returns("") # as not to depend on Rack env
    assert_equal "#{url_base}/auth/slack/done", strategy.callback_url
  end
end

class UidTest < StrategyTestCase
  def setup
    super
    strategy.stubs(:raw_info).returns("user_id" => "U123")
  end

  test "returns the user ID from raw_info" do
    assert_equal "U123", strategy.uid
  end
end

class CredentialsTest < StrategyTestCase
  def setup
    super
    @access_token = stub("OAuth2::AccessToken")
    @access_token.stubs(:token)
    @access_token.stubs(:expires?)
    @access_token.stubs(:expires_at)
    @access_token.stubs(:refresh_token)
    strategy.stubs(:access_token).returns(@access_token)
  end

  test "returns a Hash" do
    assert_kind_of Hash, strategy.credentials
  end

  test "returns the token" do
    @access_token.stubs(:token).returns("123")
    assert_equal "123", strategy.credentials["token"]
  end

  test "returns the expiry status" do
    @access_token.stubs(:expires?).returns(true)
    assert strategy.credentials["expires"]

    @access_token.stubs(:expires?).returns(false)
    refute strategy.credentials["expires"]
  end

  test "returns the refresh token and expiry time when expiring" do
    ten_mins_from_now = (Time.now + 600).to_i
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns("321")
    @access_token.stubs(:expires_at).returns(ten_mins_from_now)
    assert_equal "321", strategy.credentials["refresh_token"]
    assert_equal ten_mins_from_now, strategy.credentials["expires_at"]
  end

  test "does not return the refresh token when test is nil and expiring" do
    @access_token.stubs(:expires?).returns(true)
    @access_token.stubs(:refresh_token).returns(nil)
    assert_nil strategy.credentials["refresh_token"]
    refute_has_key "refresh_token", strategy.credentials
  end

  test "does not return the refresh token when not expiring" do
    @access_token.stubs(:expires?).returns(false)
    @access_token.stubs(:refresh_token).returns("XXX")
    assert_nil strategy.credentials["refresh_token"]
    refute_has_key "refresh_token", strategy.credentials
  end
end

class UserInfoTest < StrategyTestCase

  def setup
    super
    @access_token = stub("OAuth2::AccessToken")
    strategy.stubs(:access_token).returns(@access_token)
  end

  test "performs a GET to https://slack.com/api/users.info" do
    strategy.stubs(:raw_info).returns("user_id" => "U123")
    @access_token.expects(:get).with("/api/users.info?user=U123")
      .returns(stub_everything("OAuth2::Response"))
    strategy.user_info
  end

  test "URI escapes user ID" do
    strategy.stubs(:raw_info).returns("user_id" => "../haxx?U123#abc")
    @access_token.expects(:get).with("/api/users.info?user=..%2Fhaxx%3FU123%23abc")
      .returns(stub_everything("OAuth2::Response"))
    strategy.user_info
  end
end

class SkipInfoTest < StrategyTestCase

  test 'info should not include extended info when skip_info is specified' do
    @options = { skip_info: true }
    strategy.stubs(:raw_info).returns({})
    assert_equal %w[nickname team user team_id user_id], strategy.info.keys.map(&:to_s)
  end

  test 'extra should not include extended info when skip_info is specified' do
    @options = { skip_info: true }
    strategy.stubs(:raw_info).returns({})
    strategy.stubs(:webhook_info).returns({})
    assert_equal %w[raw_info web_hook_info bot_info], strategy.extra.keys.map(&:to_s)
  end

end
