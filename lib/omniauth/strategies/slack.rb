require 'omniauth/strategies/oauth2'

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
        {
          name: user_info['user'].to_h['profile'].to_h['real_name_normalized'],
          email: user_info['user'].to_h['profile'].to_h['email'],
          nickname: raw_info['user'],
          first_name: user_info['user'].to_h['profile'].to_h['first_name'],
          last_name: user_info['user'].to_h['profile'].to_h['last_name'],
          description: user_info['user'].to_h['profile'].to_h['title'],
          image_24: user_info['user'].to_h['profile'].to_h['image_24'],
          image_48: user_info['user'].to_h['profile'].to_h['image_48'],
          image: user_info['user'].to_h['profile'].to_h['image_192'],
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          team_domain: team_info['team'].to_h['domain'],
          user_id: raw_info['user_id'],
          is_admin: user_info['user'].to_h['is_admin'],
          is_owner: user_info['user'].to_h['is_owner'],
          time_zone: user_info['user'].to_h['tz']
        }
      end

      extra do
        {
          raw_info: raw_info,
          user_info: user_info,
          team_info: team_info,
          web_hook_info: web_hook_info,
          bot_info: bot_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/auth.test').parsed
      end

      def user_info
        @user_info ||= access_token.get("/api/users.info?user=#{raw_info['user_id']}").parsed
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
    end
  end
end
