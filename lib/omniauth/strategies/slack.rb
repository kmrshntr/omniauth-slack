require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Slack < OmniAuth::Strategies::OAuth2

      option :name, "slack"

      option :authorize_options, [ :scope, :team ]

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
          name: user_info['user']['profile']['real_name_normalized'],
          email: user_info['user']['profile']['email'],
          nickname: raw_info['user'],
          first_name: user_info['user']['profile']['first_name'],
          last_name: user_info['user']['profile']['last_name'],
          description: user_info['user']['profile']['title'],
          image: user_info['user']['profile']['image_192'],
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          user_id: raw_info['user_id']
        }
      end

      extra do
        {:raw_info => raw_info, :user_info => user_info}
      end

      def user_info
        @user_info ||= access_token.get("/api/users.info?user=#{raw_info['user_id']}").parsed
      end

      def raw_info
        @raw_info ||= access_token.get("/api/auth.test").parsed
      end

    end
  end
end
