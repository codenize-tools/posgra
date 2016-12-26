$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['TZ'] = 'UTC'

if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'posgra'
require 'tempfile'
require 'timecop'
require 'rspec/match_fuzzy'

RSpec.configure do |config|
  config.before(:all) do
    drop_test_db
  end

  config.before(:each) do
    create_test_db
  end

  config.after(:each) do
    drop_test_db
  end
end

module SpecHelper
  DBHOST = ENV['POSGRA_TEST_HOST'] || '127.0.0.1'
  DBPORT = (ENV['POSGRA_TEST_PORT'] || 5432).to_i
  DBUSER = ENV['POSGRA_TEST_USER'] || 'postgres'
  DBPASS = ENV['POSGRA_TEST_PASS'] || 'password'
  DBNAME = 'posgra_test'
  DEFAULT_DBNAME = ENV['POSGRA_TEST_DEFAULT_DB'] || 'postgres'

  def apply_roles(options = {})
    tempfile(yield) do |f|
      run_client(options) do |client|
        client.apply_roles(f.path)
      end
    end
  end

  def export_roles(options = {})
    run_client(options) do |client|
      client.export_roles
    end
  end

  def apply_grants(options = {})
    tempfile(yield) do |f|
      run_client(options) do |client|
        client.apply_grants(f.path)
      end
    end
  end

  def export_grants(options = {})
    run_client(options) do |client|
      client.export_grants
    end
  end

  def apply_databases(options = {})
    tempfile(yield) do |f|
      run_client(options) do |client|
        client.apply_databases(f.path)
      end
    end
  end

  def export_databases(options = {})
    run_client(options) do |client|
      client.export_databases
    end
  end

  def run_client(options = {})
    options = {
      host: DBHOST,
      port: DBPORT,
      user: DBUSER,
      password: DBPASS,
      dbname: DBNAME,
      logger: Logger.new('/dev/null'),
      include_role: /\A(?:alice|bob|staff|engineer)/,
      exclude_role: /\A#{DBUSER}\z/,
      identifier: Posgra::Identifier::Auto.new('/dev/null')
    }.merge(options)

    if ENV['DEBUG']
      logger = Posgra::Logger.instance
      logger.set_debug(true)

      options.update(
        debug: true,
        logger: logger
      )
    end

    client = Posgra::Client.new(options)
    retval = nil

    begin
      retval = yield(client)
    ensure
      client.close
    end

    retval
  end

  def tempfile(content, options = {})
    basename = "#{File.basename __FILE__}.#{$$}"
    basename = [basename, options[:ext]] if options[:ext]

    Tempfile.open(basename) do |f|
      f.puts(content)
      f.flush
      f.rewind
      yield(f)
    end
  end

  def pg(dbname = DBNAME)
    begin
      conn = PGconn.connect(
        host: DBHOST,
        port: DBPORT,
        user: DBUSER,
        password: DBPASS,
        dbname: dbname,
      )
      retval = yield(conn)
    ensure
      conn.close if conn
    end

    retval
  end

  def create_test_db
    pg(DEFAULT_DBNAME) {|conn| conn.exec "CREATE DATABASE #{DBNAME}" }

    pg do |conn|
      conn.exec <<-SQL
        /* --- main --- */
        CREATE SCHEMA main;

        set search_path to main;

        /* microposts */
        CREATE TABLE microposts (
          id integer NOT NULL,
          content character varying(255),
          user_id integer,
          inserted_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
        );

        CREATE SEQUENCE microposts_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER TABLE ONLY microposts ALTER COLUMN id SET DEFAULT nextval('microposts_id_seq'::regclass);

        ALTER TABLE ONLY microposts ADD CONSTRAINT microposts_pkey PRIMARY KEY (id);

        /* --- master --- */
        CREATE SCHEMA master;

        set search_path to master;

        /* users */
        CREATE TABLE users (
          id integer NOT NULL,
          name character varying(255),
          email character varying(255),
          inserted_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
        );

        CREATE SEQUENCE users_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
        ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

        ALTER TABLE ONLY users ADD CONSTRAINT users_pkey PRIMARY KEY (id);

        /* schema_migrations */
        CREATE TABLE schema_migrations (
          version bigint NOT NULL,
          inserted_at timestamp without time zone
        );

        ALTER TABLE ONLY schema_migrations ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);
      SQL
    end
  end

  def drop_test_db
    pg(DEFAULT_DBNAME) do |conn|
      conn.exec "SET client_min_messages = WARNING"
      conn.exec "DROP DATABASE IF EXISTS #{DBNAME}"

      conn.exec <<-SQL
        DROP ROLE IF EXISTS alice;
        DROP ROLE IF EXISTS bob;
        DROP ROLE IF EXISTS staff;
        DROP ROLE IF EXISTS engineer;
        DROP ROLE IF EXISTS "alice alice";
        DROP ROLE IF EXISTS "bob-bob";
        DROP ROLE IF EXISTS "staff staff";
        DROP ROLE IF EXISTS "engineer-engineer";
      SQL
    end
  end
end
