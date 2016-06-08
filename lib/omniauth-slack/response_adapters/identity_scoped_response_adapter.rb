module OmniAuth
  module Slack
    class IdentityScopedResponseAdapter < BaseResponseAdapter
      def info(skip_info)
        hash = {
          nickname: raw_info['user']['name'],
          team: raw_info['team']['name'],
          user: raw_info['user']['name'],
          team_id: raw_info['team']['id'],
          user_id: raw_info['user']['id']
        }

        unless skip_info
          hash.merge!(
            name: user_info['name'],
            email: user_info['email'],
            image_24: user_info['image_24'],
            image_48: user_info['image_48'],
            image: user_info['image_192']
          )
        end

        hash
      end

      def raw_info
        @raw_info ||= access_token.get('/api/users.identity').parsed
      end

      def team_info
        @team_info ||= raw_info['team']
      end

      def uid
        raw_info['user']['id']
      end

      def user_info
        @user_info ||= raw_info["user"]
      end
    end
  end
end
