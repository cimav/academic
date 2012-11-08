Academic::Application.routes.draw do
  root :to => 'home#index'
  match 'home/index' => 'home#index'

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'

  match '/horarios' => 'staffs#schedule_table'
  match '/alumnos' => 'staffs#students'
  match '/alumno/archivos/:id' => 'staffs#student_files'
  match '/alumno/archivo/:id' => 'staffs#student_file'
end
