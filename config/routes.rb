Rails.application.routes.draw do
  devise_for :users

  resources :tweets, only: :index

  resources :users, only: [:index, :show, :edit, :update, :destroy] do
    resources :tweets
  end

  root to: "tweets#index"
end
