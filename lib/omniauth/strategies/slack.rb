require 'omniauth/strategies/oauth2'
require 'uri'
require 'rack/utils'

module OmniAuth
  module Strategies
    class Slack < OmniAuth::Strategies::OAuth2
      option :name, 'slack'

      option :authorize_options, [:scope, :team]

      option :client_options, {
        site: 'https://slack.com',
        token_url: '/api/oauth.access'
      }

      option :auth_token_params, {
        mode: :query,
        param_name: 'token'
      }

      uid { raw_info['user_id'] }

      info do
        hash = {
          nickname: raw_info['user'],
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          user_id: raw_info['user_id']
        }

        unless skip_info?
          hash.merge!(
            name: user_info['user'].to_h['profile'].to_h['real_name_normalized'],
            email: user_info['user'].to_h['profile'].to_h['email'],
            first_name: user_info['user'].to_h['profile'].to_h['first_name'],
            last_name: user_info['user'].to_h['profile'].to_h['last_name'],
            description: user_info['user'].to_h['profile'].to_h['title'],
            image_24: user_info['user'].to_h['profile'].to_h['image_24'],
            image_48: user_info['user'].to_h['profile'].to_h['image_48'],
            image: user_info['user'].to_h['profile'].to_h['image_192'],
            team_domain: team_info['team'].to_h['domain'],
            is_admin: user_info['user'].to_h['is_admin'],
            is_owner: user_info['user'].to_h['is_owner'],
            time_zone: user_info['user'].to_h['tz']
          )
        end

        hash
      end

      extra do
        hash = {
          raw_info: raw_info,
          web_hook_info: web_hook_info,
          bot_info: bot_info
        }

        unless skip_info?
          hash.merge!(
            user_info: user_info,
            team_info: team_info
          )
        end

        hash
      end

      def raw_info
        @raw_info ||= access_token.get('/api/auth.test').parsed
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

      def user_info
        url = URI.parse("/api/users.info")
        url.query = Rack::Utils.build_query(user: raw_info['user_id'])
        url = url.to_s

        @user_info ||= access_token.get(url).parsed
      end

      def team_info
        @team_info ||= access_token.get('/api/team.info').parsed
      end

      def web_hook_info
        return {} unless incoming_webhook_allowed?
        access_token.params['incoming_webhook']
      end

      def bot_info
        return {} unless bot_allowed?
        access_token.params['bot']
      end

      def incoming_webhook_allowed?
        return false unless options['scope']
        webhooks_scopes = ['incoming-webhook']
        scopes = options['scope'].split(',')
        (scopes & webhooks_scopes).any?
      end

      def bot_allowed?
        return false unless options['scope']
        bot_scopes = ['bot']
        scopes = options['scope'].split(',')
        (scopes & bot_scopes).any?
      end

      # You can pass  +scope+ or +team+ params to the auth request, if you need to set them dynamically.
      # You can also set these options in the OmniAuth config :authorize_params option.
      #
      # For example: /auth/slack?scope=bot
      def authorize_params
        super.tap do |params|
          %w[scope team].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

    end
  end
end
