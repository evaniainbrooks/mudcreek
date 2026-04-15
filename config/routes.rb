Rails.application.routes.draw do
  get  "/auth/:provider/callback", to: "oauth_callbacks#create"
  post "/auth/:provider/callback", to: "oauth_callbacks#create"
  get  "/auth/failure",            to: "oauth_callbacks#failure"

resource :session
  resource :registration, only: [:create]
  resources :activations, only: [:show], param: :token
  resources :passwords, param: :token

  resources :categories, only: [ :index ], param: :hashid

  resources :listings, only: [ :index, :show ], param: :hashid do
    resources :offers, only: [ :create ]
  end

  resources :auctions, only: [ :index, :show ], param: :hashid do
    resources :auction_registrations, only: [ :create ]
    resources :auction_listings, only: [ :show ], param: :hashid, path: :listings do
      resources :bids,       only: [ :create ]
      resources :proxy_bids, only: [ :create ]
    end
  end

  resource  :cart,                only: [ :show ]
  resource  :cart_address,        only: [ :create ]
  resource  :cart_guest_info,     only: [ :create ], controller: "cart_guest_info"
  resource  :cart_discount,       only: [ :create, :destroy ]
  resource  :cart_delivery_method, only: [ :create, :destroy ]
  resources :cart_items,          only: [ :create, :update, :destroy ]
  resources :watchlist_items,     only: [ :create, :destroy ]

  resources :orders, only: [ :create, :show ], param: :number do
    resource :payment, only: [ :create ], module: :orders
  end

  namespace :webhooks do
    resource :square, only: [ :create ], controller: "square"
  end

  resource :profile, only: [ :edit, :update ] do
    resources :payment_methods, only: [ :create, :destroy ] do
      member { patch :set_default }
    end
  end

  scope path: "/profile", module: "profiles" do
    get "orders",           to: "orders#show",          as: :profile_orders
    get "invoices",         to: "invoices#show",         as: :profile_invoices
    get "auctions",         to: "auctions#show",         as: :profile_auctions
    get "auctions/:hashid", to: "auctions#bid_detail",   as: :auction_bids_profile
    get "listings",         to: "listings#show",         as: :profile_listings
    get "watchlist",        to: "watchlist_items#show",    as: :profile_watchlist
    get "payment-methods",  to: "payment_methods#show",    as: :profile_payment_methods_page
    get "verification",    to: "verifications#show",      as: :profile_verification
    patch "verification",   to: "verifications#update"
  end
  resources :invoices,     only: [:show], param: :number do
    member { post :pay }
  end
  resources :locations, only: [:show], param: :hashid do
    resource :checkin,   only: [ :show, :create ], controller: "location_check_ins"
    resource :schedule,  only: [ :show ],           controller: "location_schedules"
  end
  get "/location",  to: "locations#show",           defaults: { hashid: "DEFAULT" }
  get "/schedule",  to: "location_schedules#show",  defaults: { location_hashid: "DEFAULT" }
  resources :ledgers, only: [:show], param: :hashid do
    resources :entries, only: [:create], module: :ledgers
  end

  resources :subdivisions, only: [ :index ]
  resources :pages, only: [ :show ], param: :slug

  resources :forms, only: [], param: :slug, controller: "inquiry_forms" do
    resources :inquiries, only: [ :create ]
  end

  get "/q/:slug",       to: "qr_redirects#show",  as: :qr_redirect
  get "/qr/:slug/image", to: "qr_codes#qr_image", as: :qr_code_image

  namespace :admin do
    root to: "dashboard#index"
    resource :tenant, only: [ :show, :update ]
    resources :users, only: [ :index, :show, :new, :create, :update ] do
      member { post :resend_activation }
    end
    resources :lots, only: [ :index, :create, :show, :update, :destroy ], param: :hashid do
      resource :listing_placeholder, only: [ :destroy ], module: :lots
      resource :settlement,          only: [ :show ],    module: :lots do
        post :pay
      end
    end
    resources :roles, only: [ :index, :create, :destroy ] do
      resources :permissions, only: [ :index, :create, :destroy ]
    end
    namespace :listings do
      resources :categories,            only: [ :index, :create, :edit, :update, :destroy ], param: :hashid
      resources :property_sets,         only: [ :index, :create, :show, :destroy, :update ] do
        collection { patch :reorder }
        member { get :listing_fields }
        resources :properties, only: [ :create, :destroy, :update ], module: :property_sets
      end
      resources :delivery_method_sets,  only: [ :index, :create, :show, :destroy, :update ] do
        resources :delivery_methods, only: [ :create, :destroy ], module: :delivery_method_sets
      end
    end
    resources :orders, only: [ :index, :show, :update ], param: :number
    resources :offers, only: [ :index, :show, :update ]
    resources :discount_codes,    only: [ :index, :create, :destroy ]
    resources :delivery_methods,  only: [ :index, :create, :update, :destroy ]
    resources :listings, param: :hashid do
      collection { patch :reorder }
      resources :attachments,       only: [ :destroy ], module: :listings
      resources :rental_rate_plans, only: [ :create, :destroy ], module: :listings
      resources :variants,          only: [ :create ], module: :listings
      resources :stock_movements,   only: [ :create, :destroy ], module: :listings
      resources :sales,             only: [ :create ],           module: :listings
      resources :copies,            only: [ :create ],           module: :listings
    end
    resources :auctions, param: :hashid do
      resources :auction_listings, only: [ :destroy, :update ], module: :auctions do
        collection { patch :reorder }
      end
    end
    resources :auction_listings, only: [ :create ]
    resources :auction_registrations, only: [ :index, :update ]
    resources :invoices, only: [ :index, :show, :update ], param: :number
    resources :bids, only: [ :update ]
    resources :pages
    resources :inquiry_forms
    resources :inquiries, only: [ :index, :show ]
    resources :kids, only: [ :index ]
    resources :subscription_plans, only: [ :index, :create, :show, :destroy ]
    resources :subscriptions, only: [ :show, :create, :update ]
    resources :navbar_items, except: [:show] do
      collection { patch :reorder }
    end
    resources :qr_codes, param: :slug do
      member { get :qr_image }
    end
    resources :locations, param: :hashid
    resources :listing_inference_batches, only: [ :new, :create, :show ], param: :hashid
    resources :ledgers, param: :hashid do
      resources :entries, only: [ :create, :destroy ], module: :ledgers
    end
    get    "email_aliases",        to: "email_aliases#index",   as: :email_aliases
    post   "email_aliases",        to: "email_aliases#create"
    delete "email_aliases/:id",    to: "email_aliases#destroy", as: :email_alias
    resources :sender_signatures, only: [ :index ]
    namespace :improvmx do
      resources :domains, only: [ :create ] do
        collection { post :verify }
      end
    end
    namespace :postmark do
      resources :domains, only: [ :create ] do
        collection { post :verify }
      end
    end
    resources :turnstiles, only: [ :index ]
    namespace :cloudflare do
      resources :turnstile_widgets, only: [ :create ]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "listings#index"
end
