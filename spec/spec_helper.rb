$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'posgra'

RSpec.configure do |config|
  config.before(:all) do
    drop_test_db
  end

  config.before(:each) do
    create_test_db
  end

  config.after(:each) do
    #drop_test_db
  end
end

module SpecHelper
  DBUSER = ENV['POSGRA_TEST_USER'] || ENV['USER']
  DBNAME = 'posgra_test'
  DEFAULT_DBNAME = 'postgres'

  def pg(dbname = DBNAME)
    begin
      conn = PGconn.connect(dbname: dbname)
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
    pg(DEFAULT_DBNAME) {|conn| conn.exec "DROP DATABASE IF EXISTS #{DBNAME}" }
  end
end
