Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      if Rails.env.development?
        /http:\/\/.*\.lvh\.me(:\d+)?/
      else
        ENV.fetch("DEFAULT_URL_HOST", "shop.junglefowlbjj.ca")
      end
    )
    resource "/rails/active_storage/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
