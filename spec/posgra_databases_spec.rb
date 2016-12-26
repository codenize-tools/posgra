describe 'databases' do
  include SpecHelper

  subject { export_databases }

  before do
    apply_roles do
      <<-RUBY
        group "engineer" do
          user "bob"
        end

        group "staff" do
          user "alice"
        end
      RUBY
    end

    apply_databases do
      <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT", :grantable => true
            grant "CREATE"
          end
        end
      RUBY
    end
  end

  context 'nothing to do' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "alice" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT", :grantable => true
                grant "CREATE"
              end
            end
          RUBY
        end
      ).to be_falsey

      is_expected.to match_fuzzy <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT", :grantable => true
            grant "CREATE"
          end
        end
      RUBY
    end
  end
  context 'when grant' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "alice" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT", :grantable => true
                grant "CREATE"
                grant "TEMPORARY"
              end
            end

            role "bob" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT"
                grant "CREATE"
                grant "TEMPORARY"
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT", :grantable => true
            grant "CREATE"
            grant "TEMPORARY"
          end
        end

        role "bob" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT"
            grant "CREATE"
            grant "TEMPORARY"
          end
        end
      RUBY
    end
  end

  context 'when revoke' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "alice" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT", :grantable => true
              end
            end

            role "bob" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT"
                grant "CREATE"
                grant "TEMPORARY"
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT", :grantable => true
          end
        end

        role "bob" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT"
            grant "CREATE"
            grant "TEMPORARY"
          end
        end
      RUBY
    end
  end

  context 'when revoke all' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "bob" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT"
                grant "CREATE"
                grant "TEMPORARY"
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        role "bob" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT"
            grant "CREATE"
            grant "TEMPORARY"
          end
        end
      RUBY
    end
  end

  context 'when grant grant_option' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "alice" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT", :grantable => true
                grant "CREATE", :grantable => true
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT", :grantable => true
            grant "CREATE", :grantable => true
          end
        end
      RUBY
    end
  end

  context 'when revoke grant_option' do
    it do
      expect(
        apply_databases do
          <<-RUBY
            role "alice" do
              database "#{SpecHelper::DBNAME}" do
                grant "CONNECT"
                grant "CREATE"
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to match_fuzzy <<-RUBY
        role "alice" do
          database "#{SpecHelper::DBNAME}" do
            grant "CONNECT"
            grant "CREATE"
          end
        end
      RUBY
    end
  end
end
