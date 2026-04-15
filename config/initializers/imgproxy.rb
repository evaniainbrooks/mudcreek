Imgproxy.configure do |config|
  # IMGPROXY_ENDPOINT is the public-facing URL embedded in generated image URLs
  # (what browsers request). IMGPROXY_URL is kept as a fallback for existing
  # setups where it was set to the public URL. Do not set config.endpoint to an
  # internal Docker/service hostname — browsers cannot reach it.
  config.endpoint = ENV["IMGPROXY_ENDPOINT"].presence || ENV["IMGPROXY_URL"]
  config.key      = ENV["IMGPROXY_KEY"]
  config.salt     = ENV["IMGPROXY_SALT"]

  config.url_adapters.add Imgproxy::UrlAdapters::ActiveStorage.new
end
