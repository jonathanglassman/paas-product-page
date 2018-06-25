require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "Support", :type => :feature do

	include Rack::Test::Methods

	it "should submit the first form successfully" do
		visit '/support'
		find('input#support_form-0.toggle-radio-note').set(true)
		click_button('submit')
		all('.error-summary .err').each do |err|
			expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
		end
		expect(page.status_code).to eq(200)
	end

	it "should error if not form is selected" do
		visit '/support'
		click_button('submit')
		expect(page.status_code).to eq(400)
		expect(page.current_path).to eq('/support')
	end

	[
		[ 0, "/support/something-wrong-with-service" ],
		[ 1, "/support/help-using-paas" ],
		[ 2, "/support/find-out-more" ],
	].each do |option_index, target_path|
		it "should redirect to the right support sub-form in #{target_path} when choosing #{option_index} option" do
			visit '/support'
			find("input#support_form-#{option_index}.toggle-radio-note").set(true)
			click_button('submit')
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)
			expect(page.current_path).to eq(target_path)
		end
	end

	describe "support/something-wrong-with-service" do
		let(:base_url) { "/support/something-wrong-with-service" }

		before(:each) do
			# Fill the form completely
			visit base_url
			fill_in('person_email', with: 'jeff@test.gov.uk')
			fill_in('person_name', with: 'Jeff Jefferson')
			fill_in('organization_name', with: 'TestDept')
			find("input#severity-0.toggle-radio-note").set(true)
			fill_in('message', with: 'Hello There')
		end
		it "submit the form successfully" do
			click_button('submit')
			all('.error-message').each do |err|
				expect(err.text).to be_empty, "Did not expect to see any validation errors but got: #{err.text}"
			end
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)

			expect(WebMock).to have_requested(
				:post, "#{ENV['ZENDESK_URL']}/tickets"
			).once.with{|req|
				data = JSON.parse(req.body)
				expect(data).to include("ticket")
				expect(data["ticket"]).to include("subject")
				expect(data["ticket"]["subject"]).to match(/\[PaaS Support\] .* something wrong in TestDept live service/)
				expect(data["ticket"]).to include("requester" => {"email"=>"jeff@test.gov.uk", "name"=>"Jeff Jefferson"})
				expect(data["ticket"]).to include("group_id" => ENV['ZENDESK_GROUP_ID'].to_i)
				expect(data["ticket"]).to include("tags")
				expect(data["ticket"]["tags"]).to include("govuk_paas_support")
				expect(data["ticket"]["tags"]).to include("govuk_paas_product_page")

				expect(data["ticket"]).to include("comment")
				expect(data["ticket"]["comment"]).to include("body")
				expect(data["ticket"]["comment"]["body"]).to include("From: Jeff Jefferson")
				expect(data["ticket"]["comment"]["body"]).to include("Email: jeff@test.gov.uk")
				expect(data["ticket"]["comment"]["body"]).to include("Organisation name: TestDept")
				expect(data["ticket"]["comment"]["body"]).to include("Severity: service_down")
				expect(data["ticket"]["comment"]["body"]).to include("Hello There")
			}
		end

        [
        	'person_name',
        	'person_email',
        	'organization_name',
        	'message',
		].each do |mandatory_field|
			it "should require #{mandatory_field} field" do
				fill_in(mandatory_field, with: '')
				click_button('submit')
				expect(page.status_code).to eq(400)
				expect(page.first(".form-group--#{mandatory_field} .error-message").text).not_to be_empty
			end
		end

		it "should require severity field" do
			visit base_url
			fill_in('person_email', with: 'jeff@test.gov.uk')
			fill_in('person_name', with: 'jeff')
			fill_in('organization_name', with: 'TestDept')
			fill_in('message', with: 'Hello There')
			click_button('submit')
			expect(page.status_code).to eq(400)
			expect(page.first(".form-group--severity .error-message").text).not_to be_empty
		end
	end

	describe "support/help-using-paas" do
		let(:base_url) { "/support/help-using-paas" }

		before(:each) do
			# Fill the form completely
			visit base_url
			fill_in('person_email', with: 'jeff@test.gov.uk')
			fill_in('person_name', with: 'Jeff Jefferson')
			fill_in('organization_name', with: 'TestDept')
			fill_in('message', with: 'Hello There')
		end

		it "submit the form successfully" do
			click_button('submit')
			all('.error-message').each do |err|
				expect(err.text).to be_empty, "Did not expect to see any validation errors but got: #{err.text}"
			end
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)

			expect(WebMock).to have_requested(
				:post, "#{ENV['ZENDESK_URL']}/tickets"
			).once.with{|req|
				data = JSON.parse(req.body)
				expect(data).to include("ticket")
				expect(data["ticket"]).to include("subject")
				expect(data["ticket"]["subject"]).to match(/\[PaaS Support\] .* request for help/)
				expect(data["ticket"]).to include("requester" => {"email"=>"jeff@test.gov.uk", "name"=>"Jeff Jefferson"})
				expect(data["ticket"]).to include("group_id" => ENV['ZENDESK_GROUP_ID'].to_i)
				expect(data["ticket"]).to include("tags")
				expect(data["ticket"]["tags"]).to include("govuk_paas_support")
				expect(data["ticket"]["tags"]).to include("govuk_paas_product_page")

				expect(data["ticket"]).to include("comment")
				expect(data["ticket"]["comment"]).to include("body")
				expect(data["ticket"]["comment"]["body"]).to include("From: Jeff Jefferson")
				expect(data["ticket"]["comment"]["body"]).to include("Email: jeff@test.gov.uk")
				expect(data["ticket"]["comment"]["body"]).to include("Organisation name: TestDept")
				expect(data["ticket"]["comment"]["body"]).to include("Hello There")
			}
		end

        [
        	'person_name',
        	'person_email',
        	'message',
		].each do |mandatory_field|
			it "should require #{mandatory_field} field" do
				fill_in(mandatory_field, with: '')
				click_button('submit')
				expect(page.status_code).to eq(400)
				expect(page.first(".form-group--#{mandatory_field} .error-message").text).not_to be_empty
			end
		end

		it "should not require organization_name field" do
			fill_in('organization_name', with: '')
			click_button('submit')
			expect(page.status_code).to eq(200)
		end
	end

	describe "support/find-out-more" do
		let(:base_url) { "/support/find-out-more" }

		before(:each) do
			# Fill the form completely
			visit base_url
			fill_in('person_email', with: 'jeff@test.gov.uk')
			fill_in('person_name', with: 'Jeff Jefferson')
			fill_in('organization_name', with: 'TestDept')
			fill_in('message', with: 'Hello There')
		end

		it "submit the form successfully" do
			click_button('submit')
			all('.error-message').each do |err|
				expect(err.text).to be_empty, "Did not expect to see any validation errors but got: #{err.text}"
			end
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)

			expect(WebMock).to have_requested(
				:post, "#{ENV['ZENDESK_URL']}/tickets"
			).once.with{|req|
				data = JSON.parse(req.body)
				expect(data).to include("ticket")
				expect(data["ticket"]).to include("subject")
				expect(data["ticket"]["subject"]).to match(/\[PaaS Support\] .* request for information/)
				expect(data["ticket"]).to include("requester" => {"email"=>"jeff@test.gov.uk", "name"=>"Jeff Jefferson"})
				expect(data["ticket"]).to include("group_id" => ENV['ZENDESK_GROUP_ID'].to_i)
				expect(data["ticket"]).to include("tags")
				expect(data["ticket"]["tags"]).to include("govuk_paas_support")
				expect(data["ticket"]["tags"]).to include("govuk_paas_product_page")

				expect(data["ticket"]).to include("comment")
				expect(data["ticket"]["comment"]).to include("body")
				expect(data["ticket"]["comment"]["body"]).to include("From: Jeff Jefferson")
				expect(data["ticket"]["comment"]["body"]).to include("Email: jeff@test.gov.uk")
				expect(data["ticket"]["comment"]["body"]).to include("Organisation name: TestDept")
				expect(data["ticket"]["comment"]["body"]).to include("Hello There")
			}
		end

        [
        	'person_name',
        	'person_email',
			'organization_name',
        	'message',
		].each do |mandatory_field|
			it "should require #{mandatory_field} field" do
				fill_in(mandatory_field, with: '')
				click_button('submit')
				expect(page.status_code).to eq(400)
				expect(page.first(".form-group--#{mandatory_field} .error-message").text).not_to be_empty
			end
		end
	end
end
