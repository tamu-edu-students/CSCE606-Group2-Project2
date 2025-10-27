Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  get "/sign_in", to: "sessions#new"
  delete "/sign_out", to: "sessions#destroy"

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"

  resource :dashboard, only: :show
  resource :onboarding, only: %i[new create], controller: :onboarding
  resources :food_logs, only: %i[index new create edit update destroy]
  # Profile inline goal updates (current_user)
  patch "/profile/goals", to: "profiles#update_goals"
end
