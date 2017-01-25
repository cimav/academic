module ApplicationHelper
  def active_class(link_path)
    "active" if request.fullpath == link_path
  end

  def get_all_staffs
    return @all_staffs = Staff.where(:email => !'').where(:status => Staff::ACTIVE)
  end

end
