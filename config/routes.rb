Rails.application.routes.draw do
  get 'onboarding/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "onboarding#index"
  get '/up', to: ->(env) { [200, {}, ['ok']] }
end
