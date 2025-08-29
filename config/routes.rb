Rails.application.routes.draw do
  devise_for :users
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  scope :auth do
    post   :sign_up,  to: "auth/sessions#sign_up"
    post   :sign_in,  to: "auth/sessions#create"
    delete :sign_out, to: "auth/sessions#destroy"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  get "/me", to: "me#show"
end
