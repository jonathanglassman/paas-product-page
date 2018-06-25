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

	describe "support/something-wrong-with-service" do
		it "should redirect to the right support sub-form" do
			visit '/support'
			find('input#support_form-0.toggle-radio-note').set(true)
			click_button('submit')
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)
			expect(page.current_path).to eq('/support/something-wrong-with-service')
		end
	end

	describe "support/help-using-paas" do
		it "should redirect to the right support sub-form" do
			visit '/support'
			find('input#support_form-1.toggle-radio-note').set(true)
			click_button('submit')
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)
			expect(page.current_path).to eq('/support/help-using-paas')
		end
	end

	describe "support/find-out-more" do
		it "should redirect to the right support sub-form" do
			visit '/support'
			find('input#support_form-2.toggle-radio-note').set(true)
			click_button('submit')
			all('.error-summary .err').each do |err|
				expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
			end
			expect(page.status_code).to eq(200)
			expect(page.current_path).to eq('/support/find-out-more')
		end
	end
end
