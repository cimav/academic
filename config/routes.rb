Academic::Application.routes.draw do
  root :to => 'home#index'
  match 'home/index' => 'home#index'

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'

  match '/horarios/:id/:term_id' => 'staffs#schedule_table'
end
