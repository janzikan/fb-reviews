# frozen_string_literal: true

require 'capybara'
require 'capybara/dsl'
require 'capybara-webkit'

module Config
  module Capybara
    ::Capybara.run_server = false
    ::Capybara.current_driver = :webkit

    ::Capybara::Webkit.configure do |config|
      config.allow_url('www.facebook.com')
      config.allow_url('static.xx.fbcdn.net')
      config.block_unknown_urls
    end
  end
end
