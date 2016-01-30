describe 'roles (update)' do
  include SpecHelper

  subject { export_roles }

  before do
    apply_roles do
      <<-RUBY
        user "alice"

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end

  context 'when add member' do
    it do
      apply_roles do
        <<-RUBY
          group "staff" do
            user "alice"
            user "bob"
          end
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        group "staff" do
          user "alice"
          user "bob"
        end
      RUBY
    end
  end

  context 'when drop member' do
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

  context 'when group -> user' do
    it do
      apply_roles do
        <<-RUBY
          user "alice"
          user "bob"
          user "staff"
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        user "alice"
        user "bob"
        user "staff"
      RUBY
    end
  end

  context 'when user -> group' do
    it do
      apply_roles do
        <<-RUBY
          group "alice"

          group "staff" do
            user "bob"
          end
        RUBY
      end

      is_expected.to eq <<-RUBY.unindent.chomp
        group "alice" do
          # no users
        end

        group "staff" do
          user "bob"
        end
      RUBY
    end
  end
end
