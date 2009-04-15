# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def default_nickname
    if @user
      @user.default_nickname
    else
      nil
    end
  end
end
