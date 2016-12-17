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

  context 'include object' do
    let(:include_object) { /^microposts$/ }

    it do
      expect(
        apply_grants(include_object: include_object) do
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
                end
                on "microposts_id_seq" do
                  grant "SELECT"
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
            end
            on "microposts_id_seq" do
              grant "SELECT"
              grant "UPDATE"
            end
          end
        end
      RUBY

      expect(export_grants(include_object: include_object)).to match_fuzzy <<-RUBY
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
              grant "INSERT"
              grant "REFERENCES"
              grant "SELECT"
              grant "TRIGGER"
              grant "TRUNCATE"
            end
          end
        end
      RUBY
    end
  end

  context 'exclude object' do
    let(:exclude_object) { /^microposts_id_seq$/ }

    it do
      expect(
        apply_grants(exclude_object: exclude_object) do
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
                end
                on "microposts_id_seq" do
                  grant "SELECT"
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
            end
            on "microposts_id_seq" do
              grant "SELECT"
              grant "UPDATE"
            end
          end
        end
      RUBY

      expect(export_grants(exclude_object: exclude_object)).to match_fuzzy <<-RUBY
        role "bob" do
          schema "main" do
            on "microposts" do
              grant "DELETE", :grantable => true
              grant "INSERT"
              grant "REFERENCES"
              grant "SELECT"
              grant "TRIGGER"
              grant "TRUNCATE"
            end
          end
        end
      RUBY
    end
  end
end
