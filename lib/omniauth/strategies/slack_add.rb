require 'omniauth/strategies/oauth2'
require 'uri'
require 'rack/utils'

module OmniAuth
  module Strategies
    class SlackAdd < OmniAuth::Strategies::OAuth2
      option :name, 'alt_slack'

      option :authorize_options, [:scope, :team]

      option :client_options, {
        site: 'https://slack.com',
        token_url: '/api/oauth.access'
      }

      option :auth_token_params, {
        mode: :query,
        param_name: 'token'
      }

      # User ID is not guaranteed to be globally unique across all Slack users.
      # The combination of user ID and team ID, on the other hand, is guaranteed
      # to be globally unique.
      uid { "#{identity['user_id']}-#{identity['team_id']}" }

      info do
        hash = {
          name: hash_dig(user_info, 'user', 'name') || identity['user'],
          username: identity['user'],
          email: hash_dig(user_info, 'user', 'profile', 'email'),
          team_name: identity['team'],
          team_id: identity['team_id'],
        }

        unless skip_info?
          [:first_name, :last_name, :phone, :image_48].each do |key|
            hash[key] = hash_dig(user_info, 'user', 'profile', key)
          end
        end

        hash
      end

      extra do
        {
          raw_info: {
            user_info: user_info,         # Requires the users:read scope
            team_info: team_info,         # Requires the team:read scope
            web_hook_info: web_hook_info,
            bot_info: bot_info
          }
        }
      end

      def authorize_params
        super.tap do |params|
          %w[scope team].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      def hash_dig(hash, *keys)
        keys.inject(hash) do |result, method|
          result[method.to_s] if result
        end
      end

      def identity
        url = '/api/auth.test'

        @identity ||= access_token.get(url).parsed
      end

      def user_info
        url = URI.parse('/api/users.info')
        url.query = Rack::Utils.build_query(user: identity['user_id'])
        url = url.to_s

        @user_info ||= access_token.get(url).parsed
      end

      def team_info
        @team_info ||= access_token.get('/api/team.info').parsed
      end

      def web_hook_info
        access_token.params['incoming_webhook'].to_h
      end

      def bot_info
        access_token.params['bot'].to_h
      end
    end
  end
end
