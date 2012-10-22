class CreateTermCourseSchedules < ActiveRecord::Migration
  def change
    create_table :term_course_schedules do |t|

      t.timestamps
    end
  end
end
