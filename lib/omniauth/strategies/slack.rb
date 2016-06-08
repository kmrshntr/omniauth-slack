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

      uid { identity_scoped? ? raw_info['user']['id'] : raw_info['user_id'] }

      info do
        hash = {
          nickname: identity_scoped? ? raw_info['user']['name'] : raw_info['user'],
          team: identity_scoped? ? raw_info['team']['name'] : raw_info['team'],
          user: identity_scoped? ? raw_info['user']['name'] : raw_info['user'],
          team_id: identity_scoped? ? raw_info['team']['id'] : raw_info['team_id'],
          user_id: identity_scoped? ? raw_info['user']['id'] : raw_info['user_id']
        }

        unless skip_info?
          hash.merge!(
            name: identity_scoped? ? user_info['name'] : user_info['user'].to_h['profile'].to_h['real_name_normalized'],
            email: identity_scoped? ? user_info['email'] : user_info['user'].to_h['profile'].to_h['email'],
            image_24: identity_scoped? ? user_info['image_24'] : user_info['user'].to_h['profile'].to_h['image_24'],
            image_48: identity_scoped? ? user_info['image_48'] : user_info['user'].to_h['profile'].to_h['image_48'],
            image: identity_scoped? ? user_info['image_192'] : user_info['user'].to_h['profile'].to_h['image_192']
          )

          unless identity_scoped?
            hash.merge!(
              first_name: user_info['user'].to_h['profile'].to_h['first_name'],
              last_name: user_info['user'].to_h['profile'].to_h['last_name'],
              description: user_info['user'].to_h['profile'].to_h['title'],
              team_domain: team_info['team'].to_h['domain'],
              is_admin: user_info['user'].to_h['is_admin'],
              is_owner: user_info['user'].to_h['is_owner'],
              time_zone: user_info['user'].to_h['tz']
            )
          end
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
        @raw_info ||= identity_scoped? ?
          access_token.get('/api/users.identity').parsed :
          access_token.get('/api/auth.test').parsed
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
        if identity_scoped?
          @user_info ||= raw_info["user"]
        else
          url = URI.parse("/api/users.info")
          url.query = Rack::Utils.build_query(user: raw_info['user_id'])
          url = url.to_s

          @user_info ||= access_token.get(url).parsed
        end
      end

      def team_info
        if identity_scoped?
          @team_info ||= raw_info['team']
        else
          @team_info ||= access_token.get('/api/team.info').parsed
        end
      end

      def web_hook_info
        return {} unless access_token.params.key? 'incoming_webhook'
        access_token.params['incoming_webhook']
      end

      def bot_info
        return {} unless access_token.params.key? 'bot'
        access_token.params['bot']
      end

      def identity_scoped?
        authorize_params[:scope] =~ /identity\.basic/
      end
    end
  end
end
