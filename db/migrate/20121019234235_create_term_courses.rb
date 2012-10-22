class CreateTermCourses < ActiveRecord::Migration
  def change
    create_table :term_courses do |t|

      t.timestamps
    end
  end
end
