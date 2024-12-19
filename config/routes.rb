# frozen_string_literal: true

Rails.application.routes.draw do
  get '/login', to: 'session#new'
  post '/login', to: 'session#create'
  get '/logout', to: 'session#destroy'
  resources :users
  get '/connect_database', to: 'database#index'
  post '/connect_database', to: 'database#connect'
  post '/read_excel', to: 'excel#read_excel'

  root to: 'home#index'
end
