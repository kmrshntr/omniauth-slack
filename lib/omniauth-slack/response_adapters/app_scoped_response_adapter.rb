require 'uri'

module OmniAuth
  module Slack
    class AppScopedResponseAdapter < BaseResponseAdapter
      def info(skip_info)
        hash = {
          nickname: raw_info['user'],
          team: raw_info['team'],
          user: raw_info['user'],
          team_id: raw_info['team_id'],
          user_id: raw_info['user_id']
        }

        unless skip_info
          hash.merge!(
            name: user_info['user'].to_h['profile'].to_h['real_name_normalized'],
            email: user_info['user'].to_h['profile'].to_h['email'],
            image_24: user_info['user'].to_h['profile'].to_h['image_24'],
            image_48: user_info['user'].to_h['profile'].to_h['image_48'],
            image: user_info['user'].to_h['profile'].to_h['image_192'],
            first_name: user_info['user'].to_h['profile'].to_h['first_name'],
            last_name: user_info['user'].to_h['profile'].to_h['last_name'],
            description: user_info['user'].to_h['profile'].to_h['title'],
            team_domain: team_info['team'].to_h['domain'],
            is_admin: user_info['user'].to_h['is_admin'],
            is_owner: user_info['user'].to_h['is_owner'],
            time_zone: user_info['user'].to_h['tz']
          )
        end

        hash
      end

      def raw_info
        @raw_info ||= access_token.get('/api/auth.test').parsed
      end

      def team_info
        @team_info ||= access_token.get('/api/team.info').parsed
      end

      def user_info
        url = URI.parse("/api/users.info")
        url.query = Rack::Utils.build_query(user: raw_info['user_id'])
        url = url.to_s

        @user_info ||= access_token.get(url).parsed
      end

      def uid
        raw_info['user_id']
      end
    end
  end
end
