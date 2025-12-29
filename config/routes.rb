Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root "pages#home"
  post "/start_simulation", to: "simulations#start", as: :start_simulation
  get "/s/:token", to: "simulations#show", as: :simulation
  get "/s/:token/groups/:name", to: "groups#show", as: :group
  get "s/:token/matches/:id", to: "matches#show", as: :match
  patch "s/:token/matches/:id", to: "matches#update", as: :update_match
end
