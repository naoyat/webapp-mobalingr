class MenuController < ApplicationController

  def index
    @title = "mobaLingr: Chatrooms for the mobile people"

    unless @c.logged_in?
      get_hot_rooms if ApiUsage.last_usage_of_get_hot_rooms > 10.minutes
      @hot_rooms = Room.hot_rooms

      get_new_rooms if ApiUsage.last_usage_of_get_new_rooms > 10.minutes
      @new_rooms = Room.new_rooms
    end
  end

  def close
    close_lingr_session
    redirect_to :action => 'index'
  end

  def get_hot_rooms
    if ApiUsage.get_hot_rooms_available?
      resp = @c.get_hot_rooms
      ApiUsage.record_get_hot_rooms
      if resp[:succeeded]
        Room.hot_rooms = resp[:response]['rooms'].rooms
      end
    end
  end

  def get_new_rooms
    if ApiUsage.get_new_rooms_available?
      resp = @c.get_new_rooms
      ApiUsage.record_get_new_rooms
      if resp[:succeeded]
        Room.new_rooms = resp[:response]['rooms'].rooms
      end
    end
  end

end
