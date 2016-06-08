require 'omniauth/strategies/oauth2'
require 'omniauth-slack/response_adapters'
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

      uid { response_adapter.uid }

      info do
        response_adapter.info(skip_info?)
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
        response_adapter.raw_info
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
        response_adapter.user_info
      end

      def team_info
        response_adapter.team_info
      end

      def web_hook_info
        return {} unless access_token.params.key? 'incoming_webhook'
        access_token.params['incoming_webhook']
      end

      def bot_info
        return {} unless access_token.params.key? 'bot'
        access_token.params['bot']
      end

      def response_adapter
        @response_adapter ||=
          identity_scoped? ?
            OmniAuth::Slack::IdentityScopedResponseAdapter.new(access_token) :
            OmniAuth::Slack::AppScopedResponseAdapter.new(access_token)
      end

      def identity_scoped?
        authorize_params[:scope] =~ /identity\.basic/
      end
    end
  end
end
