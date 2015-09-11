# Omniauth::Slack

This Gem contains the Slack strategy for OmniAuth.

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
  provider :slack, "API_KEY", "API_SECRET", scope: "client"
end
```

Replace `"API_KEY"` and `"API_SECRET"` with the appropriate values you obtained [earlier](https://api.slack.com/applications).

If you are using [Devise](https://github.com/plataformatec/devise) then it will look like this:

```ruby
Devise.setup do |config|
  # other stuff...

  config.omniauth :slack, ENV["SLACK_APP_ID"], ENV["SLACK_APP_SECRET"], scope: 'client'

  # other stuff...
end
```

Slack lets you choose from a [few different scopes](https://api.slack.com/docs/oauth#auth_scopes).


## Authentication Options

### Team

> If you don't pass a team param, the user will be allowed to choose which team they are authenticating against. Passing this param ensures the user will auth against an account on that particular team.

If you need to ensure that the users use the team whose team_id is 'XXXXXXXX', you can do so by passing `:team` option in your `config/initializers/omniauth.rb` like this:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack, "API_KEY", "API_SECRET", scope: "identify,read,post", team: 'XXXXXXXX'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/kmrshntr/omniauth-slack/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
