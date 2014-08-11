Academic::Application.routes.draw do
  root :to => 'home#index'
  match 'home/index' => 'home#index'

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'

  match '/horarios' => 'staffs#schedule_table'
  match '/alumnos' => 'staffs#students'
  match '/calificaciones' => 'staffs#grades'
  match '/calificar/:tc_id' => 'staffs#get_grades'
  match '/calificar/:tc_id/set' => 'staffs#set_grades'
  match '/alumno/archivos/:id' => 'staffs#student_files'
  match '/alumno/archivo/:id' => 'staffs#student_file'
  match '/clase/:tc_id' => 'staffs#show_classroom_students' 
 
  resources :student_advances_file_messages, :path=>'/avances/mensajes'
end
