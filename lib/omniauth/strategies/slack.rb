require 'omniauth/strategies/oauth2'
require 'uri'
require 'rack/utils'

module OmniAuth
  module Strategies
    # Slack OmniAuth Strategy
    class Slack < OmniAuth::Strategies::OAuth2
      option :name, 'slack'

      option :authorize_options, [:scope, :team]

      option :client_options, site: 'https://slack.com',
                              token_url: '/api/oauth.access'

      option :auth_token_params, mode: :query,
                                 param_name: 'token'

      uid { raw_info['user_id'] }

      info do
        hash = {
          nickname: raw_info['user'],
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          user_id: raw_info['user_id']
        }
        hash.merge!(additional_info) unless skip_info?
        hash
      end

      extra do
        hash = {
          raw_info: raw_info,
          web_hook_info: web_hook_info,
          bot_info: bot_info
        }

        unless skip_info?
          hash[:user_info] = user_info
          hash[:team_info] = team_info
        end

        hash
      end

      def raw_info
        @raw_info ||= access_token.get('/api/auth.test').parsed
      end

      def authorize_params
        super.tap do |params|
          %w(scope team).each do |v|
            params[v.to_sym] = request.params[v] if request.params[v]
          end
        end
      end

      def user_info
        @user_info ||= access_token.get(api_users_info_url).parsed
      end

      def team_info
        @team_info ||= access_token.get('/api/team.info').parsed
      end

      def web_hook_info
        return {} unless access_token.params.key? 'incoming_webhook'
        access_token.params['incoming_webhook']
      end

      def bot_info
        return {} unless access_token.params.key? 'bot'
        access_token.params['bot']
      end

      protected

      def api_users_info_url
        url = URI.parse('/api/users.info')
        url.query = Rack::Utils.build_query(user: raw_info['user_id'])
        url.to_s
      end

      def user_info_user
        @user_info_user ||= user_info.fetch('user', {})
      end

      def user_info_profile
        @user_info_profile ||= user_info_user.fetch('profile', {})
      end

      def team_info_team
        @team_info_team ||= team_info.fetch('team', {})
      end

      def additional_info
        {
          name: user_info_profile['real_name_normalized'],
          email: user_info_profile['email'],
          first_name: user_info_profile['first_name'],
          last_name: user_info_profile['last_name'],
          description: user_info_profile['title'],
          image_24: user_info_profile['image_24'],
          image_48: user_info_profile['image_48'],
          image: user_info_profile['image_192'],
          team_domain: team_info_team['domain'],
          is_admin: user_info_user['is_admin'],
          is_owner: user_info_user['is_owner'],
          time_zone: user_info_user['tz']
        }
      end
    end
  end
end
