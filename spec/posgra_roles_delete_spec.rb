describe 'roles (delete)' do
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

  context 'when drop user' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            group "staff" do
              user "bob"
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        group "staff" do
          user "bob"
        end
      RUBY
    end
  end

  context 'when drop user in group' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            user "alice"
            group "staff"
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        user "alice"

        group "staff" do
          # no users
        end
      RUBY
    end
  end

  context 'when drop group' do
    it do
      expect(
        apply_roles do
          <<-RUBY
            user "alice"
            user "bob"
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        user "alice"
        user "bob"
      RUBY
    end
  end

  context 'when drop user and group' do
    it do
      apply_roles { '' }
      is_expected.to be_empty
    end
  end
end
