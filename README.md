# Posgra

Posgra is a tool to manage PostgreSQL roles/permissions.

It defines the state of PostgreSQL roles/permissions using Ruby DSL, and updates roles/permissions according to DSL.

[![Gem Version](https://badge.fury.io/rb/posgra.svg)](https://badge.fury.io/rb/posgra)
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
  posgra database SUBCOMMAND  # Manage database grants
  posgra grant SUBCOMMAND     # Manage grants
  posgra help [COMMAND]       # Describe available commands or one specific command
  posgra role SUBCOMMAND      # Manage roles

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

A default connection to a database can be established by setting the following environment variables:
- `POSGRA_DB_HOST`: database host
- `POSGRA_DB_PORT`: database port
- `POSGRA_DB_DATABASE`: database database name
- `POSGRA_DB_USER`: database user
- `POSGRA_DB_PASSWORD`: database password

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

```sh
posgra database export pg_dbgrants.rb
vi pg_dbgrants.rb
posgra database apply --dry-run pg_dbgrants.rb
posgra database apply pg_dbgrants.rb
```

### for Redshift

```sh
export POSGRA_DEFAULT_ACL_PRIVS=arwdRxt
posgra grant export pg_grants.rb
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
    on "microposts_id_seq", expired: '2014/10/07' do
      grant "SELECT"
      grant "UPDATE"
    end
    on /^user/ do
      grant "SELECT"
    end
  end
end
```

### DB Grant

```ruby
role "alice" do
  database "my_database" do
    grant "CONNECT", :grantable => true
    grant "CREATE"
    grant "TEMPORARY"
  end
end

role "bob" do
  database "my_database" do
    grant "CONNECT"
    grant "CREATE"
    grant "TEMPORARY"
  end
end
```

### Template

```ruby
template "all grants" do
  on context.object do
    grant "DELETE", grantable: true
    grant "INSERT"
    grant "REFERENCES"
    grant "SELECT"
    grant "TRIGGER"
    grant "TRUNCATE"
    grant "UPDATE"
  end
end

template "grant select" do
  grant "SELECT"
end

role "bob" do
  schema "main" do
    include_template "all grants", object: "microposts"
    on "microposts_id_seq", expired: '2014/10/07' do
      grant "SELECT"
      grant "UPDATE"
    end
    on /^user/ do
      include_template "grant select"
    end
  end
end
```

## Running tests

```sh
docker-compose up -d
bundle install
bundle exec rake
```

### on OS X (docker-machine & VirtualBox)

Port forwarding is required.

```sh
VBoxManage controlvm default natpf1 "psql,tcp,127.0.0.1,5432,,5432"
```

## Similar tools
* [Codenize.tools](http://codenize.tools/)
