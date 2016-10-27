require 'omniauth/strategies/oauth2'
require 'uri'
require 'rack/utils'

module OmniAuth
  module Strategies
  
    # See https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema for more
    # info on the auth_hash schema.
    # 
    # Note that Slack does not consider email to be an essential field, and
    # therefore does not guarantee inclusion of email data in either the
    # signin-with-slack or the add-to-slack flow. Omniauth, however, considers
    # email to be a required field. So adhearing to omniauth's spec means
    # either forcing certain Slack scopes or always making multiple api
    # requests for each authorization, which breaks (or renders useless)
    # omniauth's skip_info feature. This version of omniauth-slack respects
    # the skip_info feature: if set, only a single api request will be made
    # for each authorization. The response of this request may or
    # may not contain email data.
    # 
    # Note that the scope requested during the authorization phase is not
    # available to omniauth's callback phase, as this information is not
    # present in the callback url or the token from Slack. Downstream
    # processing based on requested scope must be handled in the endpoint app.
    # Better yet, downstream logic should be based on actual authorized token
    # scopes, as provided by the Slack authorization response (or any further
    # Slack api response).
    # 
    # Slack is designed to allow quick authorization of users with minimally
    # scoped requests. Deeper scope authorizations are intended to be aquired
    # with further passes thru Slack's authorization process, as the needs of
    # the user and the endpoint app require. This works because Slack scopes
    # are additive - once you successfully authorize a scope, the token will
    # posses that scope forever, regardless of what flow or scopes are
    # requested at future authorizations. Removal of scopes requires deletion
    # of the token.
    # 
    # Other noteable features of this omniauth-slack version.
    # 
    # * Use compound user-team uid.
    # 
    # * Incude complete token scope in credentials section of auth_hash.
    # 
    # * Use any/all user & team api methods to gather additional informaion,
    #   regardless of the current request scope. Which api requests are used is
    #   determined by the requirements of the auth_hash and the token's full
    #   set of authorized scopes.
    # 
    # * In the extra:raw_info section, return as much of each api response as
    #   possible for all api requests made for the current authorization
    #   request. Possible calls are oauth.access, users.info, team.info,
    #   users.identity, users.profile.get, and bots.info. An attempt is made
    #   to use as few api requests as possible.
    #
    # * Allow setting of Slack subdomain at runtime.
    #   See #subdomain definition below.
    #
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

      # User ID is not guaranteed to be globally unique across all Slack users.
      # The combination of user ID and team ID, on the other hand, is guaranteed
      # to be globally unique.
      uid { "#{auth['user_id'] || auth['user'].to_h['id']}-#{auth['team_id'] || auth['team'].to_h['id']}" }

      info do
        # Start with only what we can glean from the authorization response.
        hash = { 
          name: auth['user'].to_h['name'],
          email: auth['user'].to_h['email'],
          user_id: auth['user_id'] || auth['user'].to_h['id'],
          team: auth['team_name'] || auth['team'].to_h['name'],
          team_id: auth['team_id'] || auth['team'].to_h['id'],
          image: auth['team'].to_h['image_48']
        }

        # Now add everything else, requiring further calls to the api, if necessary.
        unless skip_info?
          %w(first_name last_name phone skype avatar_hash real_name real_name_normalized).each do |key|
            hash[key.to_sym] = (
              user_info['user'].to_h['profile'] ||
              user_profile['profile']
            ).to_h[key]
          end

          %w(deleted status color tz tz_label tz_offset is_admin is_owner is_primary_owner is_restricted is_ultra_restricted is_bot has_2fa).each do |key|
            hash[key.to_sym] = user_info['user'].to_h[key]
          end

          more_info = {
            image: (
              hash[:image] ||
              user_identity.to_h['image_48'] ||
              user_info['user'].to_h['profile'].to_h['image_48'] ||
              user_profile['profile'].to_h['image_48']
              ),
            name:(
              hash[:name] ||
              user_identity['name'] ||
              user_info['user'].to_h['real_name'] ||
              user_profile['profile'].to_h['real_name']
              ),
            email:(
              hash[:email] ||
              user_identity.to_h['email'] ||
              user_info['user'].to_h['profile'].to_h['email'] ||
              user_profile['profile'].to_h['email']
              ),
            team:(
              hash[:team] ||
              team_identity.to_h['name'] ||
              team_info['team'].to_h['name']
              ),
            team_domain:(
              auth['team'].to_h['domain'] ||
              team_identity.to_h['domain'] ||
              team_info['team'].to_h['domain']
              ),
            team_image:(
              auth['team'].to_h['image_44'] ||
              team_identity.to_h['image_44'] ||
              team_info['team'].to_h['icon'].to_h['image_44']
              ),
            team_email_domain:(
              team_info['team'].to_h['email_domain']
              ),
            nickname:(
              user_info.to_h['user'].to_h['name'] ||
              auth['user'].to_h['name'] ||
              user_identity.to_h['name']
              ),
          }
          
          hash.merge!(more_info)
        end
        hash
      end

      extra do
        {
          web_hook_info: web_hook_info,
          #bot_info: bot_info,
          bot_info: auth['bot'] || bots_info['bot'],
          auth: auth,
          identity: @identity,
          user_info: @user_info,
          user_profile: @user_profile,
          team_info: @team_info,
          raw_info: {
            auth: access_token.dup.tap{|i| i.remove_instance_variable(:@client)},
            identity: @identity_raw,
            user_info: @user_info_raw,
            user_profile: @user_profile_raw,
            team_info: @team_info_raw,
            bot_info: @bots_info_raw
          }
        }
      end
      
      credentials do
        {
          token: access_token.token,
          scope: access_token['scope'],
          expires: false
        }
      end
      
      # Set team subdomain at runtime, if params['subdomain'] exists in omniauth authorization url.
      # Allows sign-in of specified team (as the slack subdomain name) to be part of the oauth flow.
      # Example: https://my.app.com/auth/slack?subdomain=myotherteam
      # ... will redirect to https://myotherteam.slack.com/oauth/authorize...
      def client
        super.tap do |c|
          c.site = "https://#{request.params['subdomain']}.slack.com" if request.params['subdomain']
        end
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
      
      def auth
        access_token.params.to_h.merge({token: access_token.token})
      end

      def identity
        return {} unless has_scope?('identity.basic')
        @identity_raw ||= access_token.get('/api/users.identity')
        @identity ||= @identity_raw.parsed
      end

      def user_identity
        @user_identity ||= identity['user'].to_h
      end

      def team_identity
        @team_identity ||= identity['team'].to_h
      end

      def user_info
        return {} unless has_scope?('users:read')
        url = URI.parse('/api/users.info')
        url.query = Rack::Utils.build_query(user: auth['user_id'] || auth['user'].to_h['id'])
        url = url.to_s

        @user_info_raw ||= access_token.get(url)
        @user_info ||= @user_info_raw.parsed
      end
      
      def user_profile
        return {} unless has_scope?('users.profile:read')
        url = URI.parse('/api/users.profile.get')
        url.query = Rack::Utils.build_query(user: auth['user_id'] || auth['user'].to_h['id'])
        url = url.to_s

        @user_profile_raw ||= access_token.get(url)
        @user_profile ||= @user_profile_raw.parsed
      end

      def team_info
        return {} unless has_scope?('team:read')
        @team_info_raw ||= access_token.get('/api/team.info')
        @team_info ||= @team_info_raw.parsed
      end

      def web_hook_info
        return {} unless access_token.params.key? 'incoming_webhook'
        access_token.params['incoming_webhook']
      end
      
      def bots_info
        return {} unless has_scope?('users:read')
        @bots_info_raw ||= access_token.get('/api/bots.info')
        @bots_info ||= @bots_info_raw.parsed
      end

      # Old bot method.
      # def bot_info
      #   return {} unless access_token.params.key? 'bot'
      #   access_token.params['bot']
      # end
      
      def has_scope?(scope)
        access_token['scope'].to_s.include?(scope.to_s)
      end
    end
  end
end