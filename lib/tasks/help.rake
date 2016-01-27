# coding: utf-8
namespace :help do
  desc "Grades Close at end of term"
  task :reset, [:student_id] => :environment do |t,args|
    s = Student.find(args[:student_id])
    puts s.full_name
    puts s.status

    terms  = Term.where("name like '%2016-1%' and program_id=?",s.program_id).map{|i| i.id} rescue []
    #terms  = Term.where("name like '%2016-1%'").map{|i| i.id} rescue []
    ts = s.term_students.where(:term_id=>terms).map{|i| i.id} rescue []
    TermCourseStudent.where(:term_student_id=>ts).delete_all
    TermStudentPayment.where(:term_student_id=>ts).delete_all
    TermStudentMessage.where(:term_student_id=>ts).delete_all
    s.term_students.where(:term_id=>terms).delete_all
    s.status= 6
    s.save
    puts "The End"
  end

  task :show,[:student_id] => :environment do |t,args|
    s = Student.find(args[:student_id])
    puts s.full_name
    puts s.status
    terms  = Term.where("name like '%2016-1%' and program_id=?",s.program_id).map{|i| i.id} rescue []
    ts = s.term_students.where(:term_id=>terms).map{|i| i.id} rescue []
    puts "TermStudent"
    s.term_students.where(:term_id=>terms).each do |its|
      puts "  id: #{its.id} term_id: #{its.term_id} status: #{its.status}"
    end
    puts "TermCourseStudent"
    TermCourseStudent.where(:term_student_id=>ts).each do |itcs|
      puts "  id: #{itcs.id} #{itcs.term_course.course.name} status: #{itcs.status}"
    end
    puts "TermStudentPayment"
    TermStudentPayment.where(:term_student_id=>ts).each do |itsp|
      puts "  id: #{itsp.id} amount: #{itsp.amount} status: #{itsp.status} folio: #{itsp.folio}"
    end
    puts "TermStudentMessage"
    TermStudentMessage.where(:term_student_id=>ts).each do |itsm|
      puts "  id: #{itsm.id} message: #{itsm.message} created_at: #{itsm.created_at}"
    end
  end
end
