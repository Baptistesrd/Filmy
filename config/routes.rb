Rails.application.routes.draw do
  root to: "pages#home"
  devise_for :users

  resources :watch_sessions do
    resources :chats, only: [:create]
  end

  resources :chats, only: [:show, :create, :destroy] do
    resources :messages, only: [:create]
  end

  resources :films, only: [:index, :destroy]

  post "recommended_films/:id/save",
       to: "recommended_films#save_to_library",
       as: :save_recommended_film

  resources :ratings, only: [:create, :update, :destroy]
  resources :feedbacks, only: [:create, :destroy]

  get  "/discover",           to: "swipe#index",     as: :discover
  post "/discover/recommend", to: "swipe#recommend", as: :discover_recommend
  resources :swipe_preferences, only: [:create]

  get "up" => "rails/health#show", as: :rails_health_check
end

