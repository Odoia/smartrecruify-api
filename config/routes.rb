Rails.application.routes.draw do
  devise_for :users

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  get "up" => "rails/health#show", as: :rails_health_check

  scope :auth do
    post   :sign_up,   to: "auth/sessions#sign_up"
    post   :sign_in,   to: "auth/sessions#create"
    delete :sign_out,  to: "auth/sessions#destroy"

    # Refresh token
    post   :refresh,   to: "auth/refresh_tokens#create"
    delete :refresh,   to: "auth/refresh_tokens#destroy"
  end

  namespace :education do
    resources :education_records, only: [:index, :create, :update, :destroy]
    resources :courses, only: [:index, :show] 
    resources :course_enrollments, only: [:index, :create, :update, :destroy]
    resources :language_skills, only: [:index, :create, :update, :destroy]
  end

  namespace :employment do
    resources :employment_records, only: [:index, :create, :update, :destroy] do
      resources :employment_experiences, only: [:index, :create, :update, :destroy]
    end
  end

  get "/me", to: "me#show"
end
