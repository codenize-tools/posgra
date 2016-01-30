require 'spec_helper'

describe 'roles (create)' do
  include SpecHelper

  subject { export_roles }

  context 'nothing to do' do
    it do
      is_expected.to be_empty
    end
  end

  context 'when create user' do
    it do
      apply_roles do
        <<-RUBY
          user "alice"
          user "bob"
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        user "alice"
        user "bob"
      RUBY
    end
  end

  context 'when create group only' do
    it do
      apply_roles do
        <<-RUBY
          group "staff"
          group "engineer"
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        group "engineer" do
          # no users
        end

        group "staff" do
          # no users
        end
      RUBY
    end
  end

  context 'when create group and user' do
    it do
      apply_roles do
        <<-RUBY
          group "staff" do
            user "alice"
            user "bob"
          end

          group "engineer" do
            user "bob"
          end
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        group "engineer" do
          user "bob"
        end

        group "staff" do
          user "alice"
          user "bob"
        end
      RUBY
    end
  end

  context 'when create group and toplevel user' do
    it do
      apply_roles do
        <<-RUBY
          user "alice"

          group "staff" do
            user "bob"
          end
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        user "alice"

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end
end
