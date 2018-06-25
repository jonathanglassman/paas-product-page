require 'webmock/rspec'
require 'json'

WebMock.allow_net_connect!

FAKE_ZENDESK_ENDPOINT = 'api.zendesk-mockendpoint.com'
FAKE_ZENDESK_USER = 'user@example.com'
FAKE_ZENDESK_TOKEN = '1:XXXXYYYYZZZZ'

ENV['ZENDESK_URL'] = 'https://' + FAKE_ZENDESK_ENDPOINT + '/api/v2'
ENV['ZENDESK_USER'] = FAKE_ZENDESK_USER
ENV['ZENDESK_TOKEN'] = FAKE_ZENDESK_TOKEN
ENV['ZENDESK_GROUP_ID'] = '1'

RSpec.configure do |config|

	config.before(:each) do
		stub_request(:post, /#{FAKE_ZENDESK_ENDPOINT}/).
			to_return(body: {:ticket => {:id => 100001}}.to_json, status: 201)
	end

	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
	end

	config.mock_with :rspec do |mocks|
		# Prevents you from mocking or stubbing a method that does not exist on
		# a real object. This is generally recommended, and will default to
		# `true` in RSpec 4.
		mocks.verify_partial_doubles = true
	end

	config.shared_context_metadata_behavior = :apply_to_host_groups
end
