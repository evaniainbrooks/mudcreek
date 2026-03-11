Imgproxy.configure do |config|
  config.endpoint = ENV["IMGPROXY_URL"]
  config.key      = ENV["IMGPROXY_KEY"]
  config.salt     = ENV["IMGPROXY_SALT"]

  config.url_adapters.add Imgproxy::UrlAdapters::ActiveStorage.new
end
