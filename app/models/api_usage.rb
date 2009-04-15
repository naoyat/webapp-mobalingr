class ApiUsage < ActiveRecord::Base

  private
  def self.get(api_id, room_id=nil, ticket=nil)
    if room_id && ticket
      rs = self.find(:all,
                     :conditions => ['api_id = ? AND room_id = ? AND ticket = ?',
                                     api_id, room_id, ticket],
                     :order => 'used_at DESC',
                     :limit => 1)
    else
      rs = self.find(:all,
                     :conditions => ['api_id = ?', api_id],
                     :order => 'used_at DESC',
                     :limit => 1)
    end
    rs.size >= 1 ? rs[0] : nil
  end

  def self.last_usage(api_name, room_id=nil, ticket=nil)
    last_usage = self.get(api_name, room_id, ticket)
    if last_usage
      Time.now - last_usage.used_at
    else
      1.hour
    end
  end

  def self.record_usage(api_name, room_id=nil, ticket=nil)
    last_usage = self.get(api_name, room_id, ticket)
    if last_usage
      last_usage.used_at = Time.now
      last_usage.save
    else
      self.create(:api_id => api_name,
                  :room_id => room_id,
                  :ticket => ticket,
                  :used_at => Time.now)
    end
  end

  public
  def self.last_usage_of_get_user_info
    self.last_usage('user.getInfo')
  end
  def self.get_user_info_available?
    self.last_usage_of_get_user_info > 60
  end
  def self.record_get_user_info
    self.record_usage('user.getInfo')
  end

  # get_messages
  def self.last_usage_of_get_messages(room_id, ticket)
    self.last_usage('room.getMessages', room_id, ticket)
  end
  def self.get_messages_available?(room_id, ticket)
    self.last_usage_of_get_messages > 60
  end
  def self.record_get_messages(room_id, ticket)
    self.record_usage('room.getMessages', room_id, ticket)
  end

  # get_hot_rooms
  def self.last_usage_of_get_hot_rooms
    self.last_usage('explore.getHotRooms')
  end
  def self.get_hot_rooms_available?
    self.last_usage_of_get_hot_rooms > 60
  end
  def self.record_get_hot_rooms
    self.record_usage('explore.getHotRooms')
  end

  # get_new_rooms
  def self.last_usage_of_get_new_rooms
    self.last_usage('explore.getNewRooms')
  end
  def self.get_new_rooms_available?
    self.last_usage_of_get_new_rooms > 60
  end
  def self.record_get_new_rooms
    self.record_usage('explore.getNewRooms')
  end
end
