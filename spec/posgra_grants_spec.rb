describe 'grants' do
  include SpecHelper

  subject { export_grants }

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

    apply_grants do
      <<-RUBY
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
          end
        end
      RUBY
    end
  end

  context 'nothing to do' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE", :grantable => true
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
              end
            end
          RUBY
        end
      ).to be_falsey

      is_expected.to eq <<-RUBY.unindent.chomp
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
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
          end
        end
      RUBY
    end
  end

  context 'when grant' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "alice" do
              schema "master" do
                on "users" do
                  grant "DELETE"
                  grant "INSERT"
                  grant "REFERENCES"
                  grant "SELECT"
                  grant "TRIGGER"
                  grant "TRUNCATE"
                  grant "UPDATE"
                end
                on "users_id_seq" do
                  grant "SELECT"
                  grant "UPDATE"
                end
              end
            end

            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE", :grantable => true
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
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        role "alice" do
          schema "master" do
            on "users" do
              grant "DELETE"
              grant "INSERT"
              grant "REFERENCES"
              grant "SELECT"
              grant "TRIGGER"
              grant "TRUNCATE"
              grant "UPDATE"
            end
            on "users_id_seq" do
              grant "SELECT"
              grant "UPDATE"
            end
          end
        end

        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
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
          end
        end
      RUBY
    end
  end

  context 'when revoke' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE", :grantable => true
                  grant "INSERT"
                  grant "SELECT"
                  grant "UPDATE"
                end
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
              grant "INSERT"
              grant "SELECT"
              grant "UPDATE"
            end
          end
        end
      RUBY
    end
  end

  context 'when grant grant_option' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE", :grantable => true
                  grant "INSERT", :grantable => true
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
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
              grant "INSERT", :grantable => true
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
          end
        end
      RUBY
    end
  end

  context 'when revoke grant_option' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE"
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
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE"
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
          end
        end
      RUBY
    end
  end

  context 'when grant using regexp' do
    it do
      expect(
        apply_grants do
          <<-RUBY
            role "alice" do
              schema "master" do
                on /^users/ do
                  grant "SELECT"
                  grant "UPDATE"
                end
              end
            end

            role "bob" do
              schema "main" do
                on "microposts" do
                  grant "DELETE", :grantable => true
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
              end
            end
          RUBY
        end
      ).to be_truthy

      is_expected.to eq <<-RUBY.unindent.chomp
        role "alice" do
          schema "master" do
            on "users" do
              grant "SELECT"
              grant "UPDATE"
            end
            on "users_id_seq" do
              grant "SELECT"
              grant "UPDATE"
            end
          end
        end

        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
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
          end
        end
      RUBY
    end
  end
end
