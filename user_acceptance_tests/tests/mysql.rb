require 'minitest/spec'
require 'minitest/autorun'
require 'rest-client'
require 'json'
require 'retriable'

describe 'Database User Acceptance Tests' do
  let(:service_url) do
    get_service_url_json(
      get_test_input(ENV['TEST_INPUT_FILE_LOCATION'])
    )
  end

  before do
    self.class.wait_for_api(service_url)
  end

  it 'GET /api/inventory should return HTTP 200 OK' do
    response = RestClient.get("#{service_url}/api/inventory")
    expect(response.code).must_equal(200)
  end

  it 'GET /api/inventory/1 should return HTTP 200 OK' do
    response = RestClient.get("#{service_url}/api/inventory/1")
    expect(response.code).must_equal(200)
  end

  it 'GET /api/validateMessage should return HTTP 200 OK' do
    response = RestClient.get("#{service_url}/api/validateMessage")
    expect(response.code).must_equal(200)
  end

  it 'GET /api/behaviors should return HTTP 200 OK' do
    response = RestClient.get("#{service_url}/api/behaviors")
    expect(response.code).must_equal(200)
  end

  it 'GET /api/database/health should return HTTP 200 OK' do
    response = RestClient.get("#{service_url}/api/database/health")
    expect(response.code).must_equal(200)
  end

  it 'X-DEMO-INVALID-QUERY-PRE behavior should throw on GET /api/inventory' do
    headers = { 'X-DEMO-INVALID-QUERY-PRE' => 0 }
    err = _(-> { RestClient.get("#{service_url}/api/inventory", headers) }).must_raise(RestClient::ExceptionWithResponse)
    expect(err.http_code).must_equal(500)
    expect(err.response).must_include('ER_NO_SUCH_TABLE')
  end

  it 'X-DEMO-INVALID-QUERY-POST behavior should throw on GET /api/inventory' do
    headers = { 'X-DEMO-INVALID-QUERY-POST' => 0 }
    err = _(-> { RestClient.get("#{service_url}/api/inventory", headers) }).must_raise(RestClient::ExceptionWithResponse)
    expect(err.http_code).must_equal(500)
    expect(err.response).must_include('ER_NO_SUCH_TABLE')
  end

  it 'X-DEMO-INVALID-QUERY-PRE behavior should throw on GET /api/inventory/1' do
    headers = { 'X-DEMO-INVALID-QUERY-PRE' => 0 }
    err = _(-> { RestClient.get("#{service_url}/api/inventory/1", headers) }).must_raise(RestClient::ExceptionWithResponse)
    expect(err.http_code).must_equal(500)
    expect(err.response).must_include('ER_NO_SUCH_TABLE')
  end

  it 'X-DEMO-INVALID-QUERY-POST behavior should throw on GET /api/inventory/1' do
    headers = { 'X-DEMO-INVALID-QUERY-POST' => 0 }
    err = _(-> { RestClient.get("#{service_url}/api/inventory/1", headers) }).must_raise(RestClient::ExceptionWithResponse)
    expect(err.http_code).must_equal(500)
    expect(err.response).must_include('ER_NO_SUCH_TABLE')
  end

  def get_test_input(file_path)
    test_input = File.read(file_path)
    test_input
  end

  def get_service_url_json(test_input)
    service_url = JSON.parse(test_input)
                      .fetch('services', [{}])
                      .filter { |s| s['id'] == 'nodetron' }
                      .first
                      .fetch('urls', [])
                      .first
    if service_url.nil?
      puts 'Test input does not contain a url for testing'
      puts "Test input: \n#{test_input}"
      exit(1)
    else
      service_url
    end
  end

  def get_service_url_regex(test_input)
    service_url = test_input.scan(/testing_endpoint:'(.+)'/)[0][0]

    if service_url.nil?
      puts 'Test input does not contain a url for testing'
      puts "Test input: \n#{test_input}"
      exit(1)
    else
      service_url
    end
  end

  def self.wait_for_api(service_url)
    if @before_flag.nil?
      @before_flag = true

      # this will retry 5 additional times after the initial attempt, at each interval represented in seconds. maximum total wait time is 16 seconds.
      Retriable.retriable(intervals: [1, 2, 4, 8, 16]) do
        response = RestClient.get("#{service_url}/api/inventory")
        raise Exception unless response.code == 200
      end
    end
  end
end
