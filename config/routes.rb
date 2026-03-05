Rails.application.routes.draw do
  root to: "pages#home"
  devise_for :users

  resources :watch_sessions do
    resources :chats, only: [:create]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  resources :challenges, only: [:new, :create, :show] do
    resources :chats, only: [:create]
  end

  resources :chats, only: [:show, :create, :destroy] do
    resources :messages, only: [:create]
  end
end
