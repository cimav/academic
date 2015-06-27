Academic::Application.routes.draw do
  root :to => 'home#index'
  match 'home/index' => 'home#index'

  match '/auth/:provider/callback' => 'sessions#create'
  match '/auth/failure' => 'sessions#failure'
  match "/logout" => 'sessions#destroy'
  match '/login' => 'login#index'

  match '/horarios' => 'staffs#schedule_table'
  match '/alumnos' => 'staffs#students'
  match '/alumnos/inscripcion/materias/:id' => 'students#enrollment_courses'
  match '/alumnos/inscripcion/' => 'students#assign_courses'
  match '/calificaciones' => 'staffs#grades'
  match '/inscripciones' => 'staffs#enrollments'
  match '/calificar/:tc_id' => 'staffs#get_grades'
  match '/calificar/:tc_id/set' => 'staffs#set_grades'
  match '/calificar/avance/:id' => 'staffs#get_advance_grades'
  match '/calificar/avance/:id/set' => 'staffs#set_advance_grades'
  match '/calificar/avance/:id/get/:token' => 'staffs#get_advance_grades_token'
  match '/calificar/avance/:id/:token/set' => 'staffs#set_advance_grades_token'
  match '/archivo/avance/:id/:token' => 'staffs#get_advance_file_token'
  match '/alumno/archivos/:id' => 'staffs#student_files'
  match '/alumno/archivo/:id' => 'staffs#student_file'
  match '/clase/:tc_id' => 'staffs#show_classroom_students'

  resources :student_advances_file_messages, :path=>'/avances/mensajes'
end
