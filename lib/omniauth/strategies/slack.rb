require 'omniauth/strategies/oauth2'
require 'uri'
require 'rack/utils'

module OmniAuth
  module Strategies
    class Slack < OmniAuth::Strategies::OAuth2
      option :name, 'slack'

      option :authorize_options, [:scope, :team, :redirect_uri]

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
      uid { "#{user_identity['id']}-#{team_identity['id']}" }

      info do
        if authorize_params.scope.include?('identity.basic')
          identity_to_info
        else
          user_info_to_info
        end
      end

      extra do
        {
          raw_info: {
            auth_test: auth_test,
            team_identity: team_identity,  # Requires identify:basic scope
            user_identity: user_identity,  # Requires identify:basic scope
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

      def auth_test
        @auth_test ||= access_token.get('/api/auth.test').parsed
      end

      def identity
        @identity ||= access_token.get('/api/users.identity').parsed
      end

      def user_identity
        @user_identity ||= if authorize_params.scope.include?('identity.basic')
          identity['user'].to_h
        else
          {}
        end
      end

      def team_identity
        @team_identity ||= if authorize_params.scope.include?('identity.basic')
          identity['team'].to_h
        else
          {}
        end
      end

      def user_info
        user_id = if authorize_params.scope.include?('identity.basic')
          user_identity['id']
        else
          auth_test['user_id']
        end

        url = URI.parse('/api/users.info')
        url.query = Rack::Utils.build_query(user: user_id)
        url = url.to_s

        @user_info ||= access_token.get(url).parsed
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

      private

      # def callback_url
      #   full_host + script_name + callback_path
      # end

      def identity_to_info
        hash = {
          name: user_identity['name'],
          username: user_identity['username'],
          email: user_identity['email'],    # Requires the identity.email scope
          image: user_identity['image_48'], # Requires the identity.avatar scope
          team_name: team_identity['name']  # Requires the identity.team scope
        }

        unless skip_info?
          [:first_name, :last_name, :phone].each do |key|
            hash[key] = user_info['user'].to_h['profile'].to_h[key.to_s]
          end
        end

        hash
      end

      def user_info_to_info
        hash = {
          name: user_info['user']['real_name'],
          username: user_info['user']['name'],
          email: user_info['user']['profile']['email'],    # Requires the users:read scope
          image: user_info['user']['profile']['image_48'], # Requires the users:read scope
          team_name: team_info['team']['name']     # Requires the users:read scope
        }

        unless skip_info?
          [:first_name, :last_name, :phone].each do |key|
            hash[key] = user_info['user'].to_h['profile'].to_h[key.to_s]
          end
        end

        hash
      end

    end
  end
end
