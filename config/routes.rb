# frozen_string_literal: true

Rails.application.routes.draw do
  get '/login', to: 'session#new'
  post '/login', to: 'session#create'
  get '/logout', to: 'session#destroy'
  resources :users
  get '/connect_database', to: 'database#index'
  get '/import-data', to: 'database#form_import_data'
  post '/import-data', to: 'database#connect_and_import'
  post '/connect_database', to: 'database#connect'
  post '/read_excel', to: 'excel#read_excel'

  root to: 'home#index'
end
