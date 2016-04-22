Rails.application.routes.draw do
  devise_for :users
  
  root "static_pages#home"
  get "about" => "static_pages#about"
  get "help" => "static_pages#help"

  get "dispatcher" => "request_dispatcher#main"
  get "error/index"
  get "application" => "request_dispatcher#app_dispatcher"
  
  resources :notification, only: [:index, :show]  

  namespace :admin do
    get "home" => "home#index"
    post "checkaction" => "home#checkaction"
  end

  namespace :supplier do
    get "requests" => "home#index"
    post "approve_request" => "requests#approve"
    resources :vehicles
    resources :requests, only: [:show]    
  end

  namespace :customer do
    resources :requests
    resources :requests do
      resources :schedules, only: [:index]
    end
    resources :schedules do
      resources :trips, only: [:create]
    end
    get "profile" => "profile#show"
    get "tracking" => "tracking#index"
  end
end
