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

      uid { raw_info['user_id'] }

      info do
        {
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          user_id: raw_info['user_id']
        }
      end

      extra do
        {:raw_info => raw_info}
      end

      def raw_info
        @raw_info ||= access_token.get('/api/auth.test').parsed
      end

    end
  end
end