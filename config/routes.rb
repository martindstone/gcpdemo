Rails.application.routes.draw do
  devise_for :users
  root to: 'incidents#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :incidents do
    post 'create_pd_incident', on: :member, to: 'incidents#create_pd_incident', as: 'create_pd'
  end
end
