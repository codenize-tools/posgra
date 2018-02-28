describe 'roles (update)' do
  include SpecHelper

  subject { export_roles }

  before do
    apply_roles do
      <<-RUBY
        user "alice", :connection_limit => 100, :superuser => true, :valid_until => "2018-01-01"

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end

  context 'when add member' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            group "staff" do
              user "alice"
              user "bob"
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        group "staff" do
          user "alice"
          user "bob"
        end
      RUBY
    end
  end

  context 'when drop member' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            user "alice", :connection_limit => 100, :superuser => true, :valid_until => "2018-01-01"
            user "bob"
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        user "alice", :connection_limit => 100, :superuser => true, :valid_until => "2018-01-01 00:00:00+00"
        user "bob"
      RUBY
    end
  end

  context 'when group -> user' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            user "alice", :connection_limit => 100, :superuser => true, :valid_until => "2018-01-01"
            user "bob"
            user "staff"
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        user "alice", :connection_limit => 100, :superuser => true, :valid_until => "2018-01-01 00:00:00+00"
        user "bob"
        user "staff"
      RUBY
    end
  end

  context 'when user -> group' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            group "alice"

            group "staff" do
              user "bob"
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        group "alice" do
          # no users
        end

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end

  context 'when change role attributes' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            user "alice", :createdb => true

            group "staff" do
              user "bob"
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        user "alice", :createdb => true

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end
end
