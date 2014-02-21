require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Slack < OmniAuth::Strategies::OAuth2

      option :name, "slack"

      option :client_options, {
        site: "https://slack.com",
        token_url: "/api/oauth.access"
      }

      option :auth_token_params, {
        mode: :query,
        param_name: 'token'
      }

      extra do
        {
          'members' => access_token.get('/api/users.list').parsed['members']
        }
      end

    end
  end
end