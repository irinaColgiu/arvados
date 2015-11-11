require 'integration_helper'
require 'helpers/download_helper'

class DownloadTest < ActionDispatch::IntegrationTest
  setup do
    portfile = File.expand_path '../../../../../tmp/keep-web-ssl.port', __FILE__
    @kwport = File.read portfile
    Rails.configuration.keep_web_url = "https://localhost:#{@kwport}/c=%{uuid_or_pdh}"
    CollectionsController.any_instance.expects(:file_enumerator).never

    # Make sure Capybara can download files.
    need_selenium 'for downloading', :selenium_with_download
    DownloadHelper.clear

    # Keep data isn't populated by fixtures, so we have to write any
    # data we expect to read.
    unless /^acbd/ =~ `echo -n foo | arv-put --no-progress --raw -` && $?.success?
      raise $?.to_s
    end
  end

  ['uuid', 'portable_data_hash'].each do |id_type|
    test "download from keep-web by #{id_type} using a reader token" do
      uuid_or_pdh = api_fixture('collections')['foo_file'][id_type]
      token = api_fixture('api_client_authorizations')['active_all_collections']['api_token']
      visit "/collections/download/#{uuid_or_pdh}/#{token}/"
      within "#collection_files" do
        click_link "foo"
      end
      wait_for_download 'foo', 'foo'
    end
  end

  def wait_for_download filename, expect_data
    data = nil
    tries = 0
    while tries < 20
      sleep 0.1
      tries += 1
      data = File.read(DownloadHelper.path.join filename) rescue nil
    end
    assert_equal expect_data, data
  end

  # TODO(TC): test "view pages hosted by keep-web, using session
  # token". We might persuade selenium to send
  # "collection-uuid.dl.example" requests to localhost by configuring
  # our test nginx server to work as its forward proxy. Until then,
  # we're relying on the "Redirect to keep_web_url via #{id_type}"
  # test in CollectionsControllerTest (and keep-web's tests).
end