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
    resources :users, only: [:index, :show, :update]
    resources :setting, only: [:index, :show, :update]
  end

  namespace :supplier do
    post "approve_request" => "requests#approve"
    post "send_proposal" => "requests#send_proposal"
    post "update" => "requests#update"
    resources :vehicles
    resources :invoices, only: [:update]    
    resources :requests, only: [:show, :index, :edit]   
  end

  namespace :customer do
    resources :requests
    resources :invoices, only: [:update]
    resources :requests do
      resources :schedules, only: [:index, :update]
    end
    resources :schedules do
      resources :trips, only: [:create]
    end    
    get "profile" => "profile#show"
    get "tracking" => "tracking#index"
    get "get_itineary/:schedule_id" => "tracking#get_itineary"
  end
end
