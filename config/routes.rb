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

  # Locale switching
  patch "/locale/:locale", to: "locales#update", as: :update_locale

  post "/start_simulation", to: "simulations#start", as: :start_simulation
  get "/s/:token", to: "simulations#show", as: :simulation

  # Complete mode routes (enter scores)
  get "/s/:token/groups/:name", to: "groups#show", as: :group
  get "s/:token/matches/:id", to: "matches#show", as: :match
  patch "s/:token/matches/:id", to: "matches#update", as: :update_match

  # Knockout stage routes (complete mode)
  get "/s/:token/bracket", to: "brackets#show", as: :bracket
  get "/s/:token/knockout/:match_number", to: "knockout_matches#show", as: :knockout_match
  patch "/s/:token/knockout/:match_number", to: "knockout_matches#update", as: :update_knockout_match

  # Quick mode routes (drag & drop ranking)
  get "/s/:token/quick/groups/:name", to: "quick_groups#show", as: :quick_group
  patch "/s/:token/quick/groups/:name", to: "quick_groups#update", as: :update_quick_group

  # Quick mode bracket
  get "/s/:token/quick/bracket", to: "quick_brackets#show", as: :quick_bracket
  get "/s/:token/quick/third-place", to: "quick_brackets#third_place", as: :quick_third_place
  patch "/s/:token/quick/third-place", to: "quick_brackets#update_third_place", as: :update_quick_third_place
  get "/s/:token/quick/knockout/:match_number", to: "quick_brackets#choose_winner", as: :quick_knockout_match
  patch "/s/:token/quick/knockout/:match_number", to: "quick_brackets#set_winner", as: :set_quick_winner
end
