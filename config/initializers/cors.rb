Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      Rails.env.development? ? /http:\/\/.*\.lvh\.me(:\d+)?/ : Rails.application.routes.default_url_options[:host]
    )
    resource "/rails/active_storage/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
