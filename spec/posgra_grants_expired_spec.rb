describe 'grants' do
  include SpecHelper

  let(:logger) { Logger.new('/dev/null') }

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

    Timecop.freeze(Time.parse('2014/10/06')) do
      apply_grants do
        <<-RUBY
          role "bob" do
            schema "main" do
              on "microposts", expired: '2014/10/07' do
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
  end

  context 'when expired to do' do
    it do
      expect(logger).to receive(:warn).with('[WARN] Privilege for `microposts` has expired')

      Timecop.freeze(Time.parse('2014/10/08')) do
        expect(
          apply_grants(logger: logger) do
            <<-RUBY
              role "bob" do
                schema "main" do
                  on "microposts", expired: '2014/10/07' do
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
      end

      is_expected.to match_fuzzy <<-RUBY
        role "bob" do
          schema "main" do
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
