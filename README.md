# Omniauth::Slack

This Gem contains the Slack strategy for OmniAuth and supports the
[Sign in with Slack](https://api.slack.com/docs/sign-in-with-slack) approval flow.

[![Gem Version](https://badge.fury.io/rb/omniauth-slack.svg)](http://badge.fury.io/rb/omniauth-slack)


## Before You Begin

You should have already installed OmniAuth into your app; if not, read the [OmniAuth README](https://github.com/intridea/omniauth) to get started.

Now sign into the [Slack application dashboard](https://api.slack.com/applications) and create an application. Take note of your API keys.


## Using This Strategy

First start by adding this gem to your Gemfile:

```ruby
gem 'omniauth-slack'
```

If you need to use the latest HEAD version, you can do so with:

```ruby
gem 'omniauth-slack', github: 'kmrshntr/omniauth-slack'
```

Next, tell OmniAuth about this provider. For a Rails app, your `config/initializers/omniauth.rb` file should look like this:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack, 'API_KEY', 'API_SECRET', scope: 'identity.basic'
end
```

Replace `'API_KEY'` and `'API_SECRET'` with the appropriate values you obtained [earlier](https://api.slack.com/applications).

If you are using [Devise](https://github.com/plataformatec/devise) then it will look like this:

```ruby
Devise.setup do |config|
  # other stuff...

  config.omniauth :slack, ENV['SLACK_APP_ID'], ENV['SLACK_APP_SECRET'], scope: 'identity.basic'

  # other stuff...
end
```


## Scopes
Slack lets you choose from a [few different scopes](https://api.slack.com/docs/oauth-scopes#scopes).

However, you cannot request both `identity` scopes and other scopes at the same time.

If you need to combine regular app scopes with those used for “Sign in with Slack”, you should
configure two providers:

```ruby
provider :slack, 'API_KEY', 'API_SECRET', scope: 'identity.basic', name: :sign_in_with_slack
provider :slack, 'API_KEY', 'API_SECRET', scope: 'team:read,users:read,identify,bot'
```

Use the first provider to sign users in and the second to add the application to their team.


## Auth Hash

For the scope `team:read,users:read,identify` the resulting auth hash would look like this:

```ruby
{
  provider: "slack",
  uid: "U3BPA937E",
  info: {
    description: "Welcome to Slack",
    email: "email@example.com",
    first_name: "Matt",
    image: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-192.png",
    image_24: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-24.png",
    image_48: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-48.png",
    is_admin: true,
    is_owner: true,
    last_name: "Holmes",
    name: "Matt Holmes",
    nickname: "matty",
    team: "Mattison co.",
    team_id: "A3V3VC35Y",
    time_zone: "Europe/Amsterdam",
    user: "matty",
    user_id: "U3BPA937E"
  },
  credentials {
    expires: false,
    token: "xoxp-127131411201-127810174082-127813170226-f205827fb956488602bef2068471d7a5",
  },
  extra {
    bot_info: {},
    raw_info: {
      ok: true,
      team: "Mattison co.",
      team_id: "A3V3VC35Y",
      url: "https://mattison.slack.com/",
      user: "matty",
      user_id: "U3BPA937E"
    },
    team_info: {
      ok: true,
      team: {
        domain: "mattison",
        email_domain: "",
        icon: {
          image_102: "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-102.png",
          image_132 "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-132ng",
          image_230"https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-230ng",
          image_34 "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-34png",
          image_44 "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-44png",
          image_68 "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-68png",
          image_88 "https://a.slack-edge.com/66f9/img/avatars-teams/ava_0018-88png",
          image_default: true
        },
        id: "A3V3VC35Y",
        name: "Mattison co."
      }
    },
    user_info: {
      ok: true,
      user: {
        color: "9f69e7",
        deleted: false,
        has_2fa: false,
        id: "U3BPA937E",
        is_admin: true,
        is_bot: false,
        is_owner: true,
        is_primary_owner: true,
        is_restricted: false,
        is_ultra_restricted: false,
        name: "matty",
        profile: {
          avatar_hash: "g69720796ae3",
          first_name: "Matt",
          image_192: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-192.png",
          image_24: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-24.png",
          image_32: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-32.png",
          image_48: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-48.png",
          image_512: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-512.png",
          image_72: "https://secure.gravatar.com/avatar/69720796ae3e1c2d63cd66b2d53571a5.jpg?s=192&d=https%3A%2F%2Fa.slack-edge.com%2F7fa9%2Fimg%2Favatars%2Fava_0013-72.png",
          last_name: "Holmes",
          real_name: "Matt Holmes",
          real_name_normalized: "Matt Holmes"
        },
        real_name: "Matt Holmes",
        status: nil,
        team_id: "A3V3VC35Y",
        tz: "Europe/Amsterdam",
        tz_label: "Central European Time",
        tz_offset: 3600
      }
    },
    web_hook_info: {}
  }
}
```


## Authentication Options

### Team

> If you don't pass a team param, the user will be allowed to choose which team they are authenticating against. Passing this param ensures the user will auth against an account on that particular team.

If you need to ensure that the users use the team whose team_id is 'XXXXXXXX', you can do so by passing `:team` option in your `config/initializers/omniauth.rb` like this:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack, 'API_KEY', 'API_SECRET', scope: 'identify,read,post', team: 'XXXXXXXX'
end
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/kmrshntr/omniauth-slack/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
