# Posgra

Posgra is a tool to manage PostgreSQL roles/permissions.

It defines the state of PostgreSQL roles/permissions using Ruby DSL, and updates roles/permissions according to DSL.

[![Build Status](https://travis-ci.org/winebarrel/posgra.svg?branch=master)](https://travis-ci.org/winebarrel/posgra)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'posgra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install posgra

## Usage

```sh
$ posgra help
Commands:
  posgra grant SUBCOMMAND  # Manage grants
  posgra help [COMMAND]    # Describe available commands or one specific command
  posgra role SUBCOMMAND   # Manage roles

Options:
  -h, [--host=HOST]
                                         # Default: localhost
  -p, [--port=N]
                                         # Default: 5432
  -d, [--dbname=DBNAME]
                                         # Default: postgres
  -U, [--user=USER]
  -P, [--password=PASSWORD]
      [--account-output=ACCOUNT-OUTPUT]
                                         # Default: account.csv
      [--color], [--no-color]
                                         # Default: true
      [--debug], [--no-debug]
```

```sh
posgra role export pg_roles.rb
vi pg_roles.rb
posgra role apply --dry-run pg_roles.rb
posgra role apply pg_roles.rb
```

```sh
posgra grant export pg_grants.rb
vi pg_grants.rb
posgra grant apply --dry-run pg_grants.rb
posgra grant apply pg_grants.rb
```

## DSL Example

### Role

```ruby
user "alice"

group "staff" do
  user "bob"
end
```

### Grant

```ruby
role "bob" do
  schema "main" do
    on "microposts" do
      grant "DELETE", grantable: true
      grant "INSERT"
      grant "REFERENCES"
      grant "SELECT"
      grant "TRIGGER"
      grant "TRUNCATE"
      grant "UPDATE"
    end
    on "microposts_id_seq" do
      grant "SELECT"
      grant "UPDATE"
    end
    on /^user/ do
      grant "SELECT"
    end
  end
end
```
