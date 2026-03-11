Rails.application.routes.draw do
resource :session
  resource :registration, only: [:create]
  resources :activations, only: [:show], param: :token
  resources :passwords, param: :token

  resources :listings, only: [ :index, :show ], param: :hashid do
    resources :offers, only: [ :create ]
  end

  resources :auctions, only: [ :index, :show ], param: :hashid do
    resources :auction_registrations, only: [ :create ]
    resources :auction_listings, only: [ :show ], param: :hashid, path: :listings do
      resources :bids, only: [ :create ]
    end
  end

  resource  :cart,                only: [ :show ]
  resource  :cart_address,        only: [ :create ]
  resource  :cart_discount,       only: [ :create, :destroy ]
  resource  :cart_delivery_method, only: [ :create, :destroy ]
  resources :cart_items,          only: [ :create, :update, :destroy ]

  resources :orders, only: [ :create, :show ], param: :number do
    resource :payment, only: [ :create ], module: :orders
  end

  namespace :webhooks do
    resource :square, only: [ :create ], controller: "square"
  end

  resource :profile, only: [ :edit, :update ] do
    get "auctions/:hashid", action: :auction_bids, as: :auction_bids
    get "auctions", action: :profile_auctions, as: :profile_auctions
    get "listings", action: :profile_listings, as: :profile_listings
    resources :payment_methods, only: [ :create, :destroy ] do
      member { patch :set_default }
    end
  end
  resources :invoices,     only: [:show], param: :number do
    member { post :pay }
  end
  resources :subdivisions, only: [ :index ]

  namespace :admin do
    root to: "dashboard#index"
    resource :tenant, only: [ :show, :update ]
    resources :users, only: [ :index, :show ]
    resources :lots, only: [ :index, :create, :update, :destroy ] do
      resource :listing_placeholder, only: [ :destroy ], module: :lots
    end
    resources :roles, only: [ :index, :create, :destroy ] do
      resources :permissions, only: [ :index, :create, :destroy ]
    end
    namespace :listings do
      resources :categories, only: [ :index, :create, :update, :destroy ], param: :hashid
    end
    resources :orders, only: [ :index, :show, :update ], param: :number
    resources :offers, only: [ :index, :show, :update ]
    resources :discount_codes,    only: [ :index, :create, :destroy ]
    resources :delivery_methods,  only: [ :index, :create, :update, :destroy ]
    resources :listings, param: :hashid do
      collection { patch :reorder }
      resources :attachments,       only: [ :destroy ], module: :listings
      resources :rental_rate_plans, only: [ :create, :destroy ], module: :listings
    end
    resources :auctions, param: :hashid do
      resources :auction_listings, only: [ :destroy, :update ], module: :auctions do
        collection { patch :reorder }
      end
    end
    resources :auction_listings, only: [ :create ]
    resources :auction_registrations, only: [ :index, :update ]
    resources :invoices, only: [ :index, :show ], param: :number
    resources :bids, only: [ :update ]
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
