class Room < ActiveRecord::Base
  has_and_belongs_to_many :tags,
  :foreign_key => 'room_cid',
  :association_foreign_key => 'tag_cid'

  def self.with_hash(hash)
    begin
      room = self.find(:first, :conditions => ['room_id = ?', hash['id']])
    rescue
      room = nil
    end

    if room
      room.update_attributes(:name          => hash['name'],
                             :description   => hash['description'],
                             :url           => hash['url'],
                             :icon_url      => hash['icon_url'],
                             :counter       => hash['counter'],
                             :max_user_message_id => hash['max_user_message_id'],
                             :requires_password => hash['requires_password'],
                             :chatter_count => hash['chatter_count'],
                             :observer_count => hash['observer_count'],
                             :timezone      => hash['timezone'])
      room.tags.delete_all
    else
      room = self.create(:room_id       => hash['id'],
                         :name          => hash['name'],
                         :description   => hash['description'],
                         :url           => hash['url'],
                         :icon_url      => hash['icon_url'],
                         :counter       => hash['counter'],
                         :max_user_message_id => hash['max_user_message_id'],
                         :requires_password => hash['requires_password'],
                         :chatter_count => hash['chatter_count'],
                         :observer_count => hash['observer_count'],
                         :timezone      => hash['timezone']
                         )
    end

    if hash['tags']
      hash['tags'].each {|h|
        tag = Tag.with_hash(h)
        tag.save
        room.tags << tag
      }
    end

    room
  end

##
  public
  def self.register_room(room_group, room, user_cid=0)
    cnt = self.connection.select_value("SELECT count(*) FROM rooms_users WHERE room_cid = #{room.id} AND user_cid = #{user_cid} AND room_group = '#{room_group}'").to_i

    self.connection.execute("INSERT INTO rooms_users (room_cid,user_cid,room_group) VALUES (#{room.id},#{user_cid},'#{room_group}')") if cnt == 0
  end

  def self.register_rooms(room_group, rooms, user_cid=0)
    self.connection.execute("DELETE FROM rooms_users WHERE user_cid = #{user_cid} AND room_group = '#{room_group}'")

    rooms.each do |room|
      register_room(room_group, room, user_cid)
    end
  end

  def self.rooms_of_group(room_group, user_cid=0)
    conns = self.connection.select_values("SELECT room_cid FROM rooms_users WHERE user_cid = #{user_cid} AND room_group = '#{room_group}'")

    rooms = Array.new
    conns.each{|room_cid|
      begin
        room = Room.find(room_cid.to_i)
        rooms << room if room
      rescue
        room = nil
      end
    }
    rooms
  end

  def self.hot_rooms=(rooms)
    self.register_rooms('hot_rooms',rooms)
  end
  def self.hot_rooms
    self.rooms_of_group('hot_rooms')
  end

  def self.new_rooms=(rooms)
    self.register_rooms('new_rooms',rooms)
  end
  def self.new_rooms
    self.rooms_of_group('new_rooms')
  end
end
