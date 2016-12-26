describe 'grants (include space/hyphen)' do
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

        group "engineer-engineer" do
          user "bob-bob"
        end

        group "staff staff" do
          user "alice alice"
        end
      RUBY
    end

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

        role "bob-bob" do
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

        role "staff staff" do
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

            role "bob-bob" do
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

            role "staff staff" do
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

      is_expected.to match_fuzzy <<-RUBY
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

        role "bob-bob" do
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

        role "staff staff" do
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

            role "bob-bob" do
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

            role "staff staff" do
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

            role "alice alice" do
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

            role "engineer-engineer" do
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

      is_expected.to match_fuzzy <<-RUBY
        role "alice alice" do
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

        role "bob-bob" do
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

        role "engineer-engineer" do
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

        role "staff staff" do
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

      is_expected.to match_fuzzy <<-RUBY
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
