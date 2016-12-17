describe 'template' do
  include SpecHelper

  describe "roles" do
    subject { export_roles }

    context 'when use template' do
      it do
        expect(
          apply_roles do
            <<-RUBY
              template "my tmpl" do
                user context.name
              end

              template "bob tmpl" do
                user "bob"
              end

              include_template "my tmpl", name: "alice"

              group "staff" do
                include_template "bob tmpl"
              end
            RUBY
          end
        ).to be_truthy

        is_expected.to match_fuzzy <<-RUBY
          user "alice"

          group "staff" do
            user "bob"
          end
        RUBY
      end
    end
  end

  describe "grants" do
    subject { export_grants }

    context 'when use template' do
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
      end

      it do
        expect(
          apply_grants do
            <<-RUBY
              template "object tmpl" do
                on context.object do
                  grant "DELETE", grantable: true
                  grant "INSERT"
                  grant "REFERENCES"
                  grant "SELECT"
                  grant "TRIGGER"
                  grant "TRUNCATE"
                  grant "UPDATE"
                end
              end

              template "grant tmpl" do
                grant "SELECT"
              end

              role "bob" do
                schema "main" do
                  include_template "object tmpl", object: "microposts"

                  on "microposts_id_seq" do
                    include_template "grant tmpl"
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
end
