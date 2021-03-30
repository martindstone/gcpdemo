Rails.application.routes.draw do
  devise_for :users
  root to: 'incidents#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :incidents do
    post 'create_pd_incident', on: :member, to: 'incidents#create_pd_incident', as: 'create_pd'
    post 'add_responders', on: :member, to: 'incidents#add_responders', as: 'add_responders'
    post 'add_subscribers', on: :member, to: 'incidents#add_subscribers', as: 'add_subscribers'
    post 'message_preview', on: :member, to: 'incidents#message_preview', as: 'message_preview'
    get 'message_preview_raw', on: :member, to: 'incidents#message_preview_raw', as: 'message_preview_raw'
    get 'message_send', on: :member, to: 'incidents#message_send', as: 'message_send'
  end
  resources :message_templates
end
