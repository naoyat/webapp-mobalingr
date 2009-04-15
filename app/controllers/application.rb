# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'api_client'

SUBNO_PSEUDO = '00000000000000_aa.ezweb.ne.jp'

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_mobalingr_session_id'

  before_filter :set_service_info
  before_filter :establish_lingr_session

  mobile_filter

  layout "common"

  private
  def establish_lingr_session
    # first, remove saved session if invalid
    load_session_data
#    @c = session[:api_client]
    if @c
      resp = @c.verify_session
      unless resp && resp[:succeeded]
        @c = nil
        clear_session_data
      end
    end

    # then, create a new session if not exists
    unless @c
      @c = Lingr::ApiClient.new(LINGR_API_KEY, 0, 'www.lingr.com') # HOSTNAME
      @c.create_session('human') ## ('automaton')
      session[:api_client] = @c
    end

    @user = User.mobile_user(request) #.mobile, request.ident_subscriber)
    if @user and @user.email and @user.password and not @c.logged_in?
      @c.login(@user.email, @user.password)
    end
  end

  protected
  def close_lingr_session
    @c.destroy_session if @c
    clear_session_data
  end
#  def valid_session?
#    return false unless @c
#
#    resp = @c.verify_session
#    resp && resp[:succeeded]
#  end

#  def logged_in?
#    return false unless valid_session?
#
#    @ticket ? true : false
#  end

  def load_session_data
    @c            = session[:api_client]
#    if session[:api_client]
    @ticket       = session[:ticket]
    @counter      = session[:counter]
    @me           = session[:me]
    @roster       = session[:roster]
    @high_counter = session[:high_counter]

#    @room         = session[:room] #?

    @user         = session[:user]
    if @user and @user.email and @user.password and not @c.logged_in?
      @c.login(@user.email, @user.password)
    end
#    @new_rooms    = session[:hot_rooms]
#    @hot_rooms    = session[:hot_rooms]
  end

  def clear_session_data
    session[:api_client]   = @c            = nil
    session[:resp]         = @resp         = nil

    session[:ticket]       = @ticket       = nil
    session[:counter]      = @counter      = nil
    session[:me]           = nil
    session[:roster]       = nil
    session[:high_counter] = nil

#    session[:room]         = @room         = nil
    session[:user]         = @user         = nil
#    session[:hot_rooms]       = @hot_room     = nil
end

#  def login(email=nil, password=nil)
#    if email and password
#      @resp = @c.login(email, password)
#
#      status = @resp[:response]['status'] #fail
#      if @resp[:succeeded]
#        code = 200
#      else
#        code = @resp[:response]['error']['code']
#      end
#      code
#      # @user_observe_thread = Thread.new { user_observe_loop(email) } if resp[:succeeded]
#    end
#  end
  def set_service_info
    if request.mobile?
      # mobile.
      return false unless request.mobile.valid_ip?
      # 今のところ特にやることはない
    else
#      if RAILS_ENV == 'development'
        if request.user_agent =~ /Camino/
          request.override_user_agent "KDDI-HI36 UP.Browser/6.2.0.10.4 (GUI) MMP/2.0"
          #        request.override_user_agent "KDDI-HI11 UP.Browser/6.2.0.10.4 (GUI) MMP/2.0"
          request.override_subno SUBNO_PSEUDO
          logger.debug "ua = #{request.user_agent}"
          logger.debug "subno = #{request.subno}"
        end
#      end
    end
 
#    if valid_subno?(request.subno)
#      logger.debug "@user = User.current_user(request)"
#    else
#      logger.debug "@user = nil, because request.subno is not valid"
#    end
  end

end

#module Lingr
#class Tag
#  def initialize(hash)
#  end
#end

#class Room
#  attr_reader :room_id, :name, :description, :url, :icon_url, :counter,
#  :max_user_message_id, :tags, :requires_password,
#  :chatter_count, :observer_count, :timezone
#end

class NilClass
#  def room_id
#    nil
#  end
#  def name
#    nil
#  end
  def rooms
    []
  end
end

class Array
  def rooms
    self.map{|hash| Room.with_hash(hash)}
#    self.map{|hash| Room.new(hash)}
  end
end

class ActionController::AbstractRequest

  def handset_type
    ua = env['HTTP_USER_AGENT']
    ua.blank? ? "????" : ua[5,4]
  end

  def subno
    env['HTTP_X_UP_SUBNO'] #|| '00000000000000_aa.ezweb.ne.jp'
  end

  def pseudo_mobile?
    mobile? and subno and subno == SUBNO_PSEUDO
  end

  def override_user_agent(ua) ; env['HTTP_USER_AGENT'] = ua ; end
  def override_subno(subno) ; env['HTTP_X_UP_SUBNO'] = subno ; end

end
