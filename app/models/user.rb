class User < ActiveRecord::Base
#  has_and_belongs_to_many :rooms,
#  :foreign_key => 'tag_cid',
#  :association_foreign_key => 'room_cid'

  def self.mobile_user(request)#, ident)
    case request.mobile
    when Jpmobile::Mobile::Docomo
      carrier = 'd'
      ident = request.ident_subscriber
    when Jpmobile::Mobile::Au
      carrier = 'a'
      ident = request.subno
    when Jpmobile::Mobile::Softbank
      carrier = 's'
      ident = request.ident_subscriber
    when Jpmobile::Mobile::Willcom
      carrier = 'w'
      ident = "**********"
    else
      carrier = '-'
      ident = "**********"
    end

    begin
      user = User.find(:first,
                       :conditions => ['carrier = ? AND uid = ?', carrier, ident])
      return user if user
    rescue
      user = nil
    end

    User.create(:valid => true,
                :carrier => carrier,
                :uid => ident,
                :easy_login => false)
  end

  def self.valid_user(email,password)
    begin
      user = self.find_by_email(email)
      unless user.password == password
        user.password = password
        user.save
      end
      return user
    rescue
      user = nil
    end

    user = self.create(:email => email,
                       :password => password)
    user
  end

  public
  def visited_rooms=(rooms) ; Room.register_rooms('visited_rooms', rooms, self.id) ; end
  def favorite_rooms=(rooms) ; Room.register_rooms('favorite_rooms', rooms, self.id) ; end
  def owned_rooms=(rooms) ; Room.register_rooms('owned_rooms', rooms, self.id) ; end
  def monitored_rooms=(rooms) ; Room.register_rooms('monitored_rooms', rooms, self.id) ; end
  def occupied_rooms=(rooms) ; Room.register_rooms('occupied_rooms', rooms, self.id) ; end

  def visited_rooms ; Room.rooms_of_group('visited_rooms', self.id) ; end
  def favorite_rooms ; Room.rooms_of_group('visited_rooms', self.id) ; end
  def owned_rooms ; Room.rooms_of_group('visited_rooms', self.id) ; end
  def monitored_rooms ; Room.rooms_of_group('visited_rooms', self.id) ; end
  def occupied_rooms ; Room.rooms_of_group('visited_rooms', self.id) ; end
end
