#
# = api_client.rb
#
# Lingr API client
#
# $Revision: 37 $
# $Date: 2007-05-18 22:38:04 +0900 (金, 18  5 2007) $
# $Date: 2007-12-28 02:06:42 +0900 (金, 28 12 2007) $ by naoya_t
#

$KCODE = 'u'
require 'jcode'
require 'net/http'
require 'cgi'

# Ruby client for the Lingr[http://www.lingr.com] API.  For more details and tutorials, see the
# {Lingr API Reference}[http://wiki.lingr.com/dev/show/API+Reference] pages on the {Lingr Developer Wiki}[http://wiki.lingr.com].
#
# All methods return a hash with two keys:
# * :succeeded - <tt>true</tt> if the method succeeded, <tt>false</tt> otherwise
# * :response - a Hash version of the response document received from the server
#

module Lingr

  class ApiClient
    attr_accessor :api_key
    # 0 = quiet, 1 = some debug info, 2 = more debug info
    attr_accessor :verbosity
    attr_accessor :session
    attr_accessor :timeout

    def initialize(api_key, verbosity=0, hostname='www.lingr.com')
      @api_key = api_key
      @host = hostname
      @verbosity = verbosity
      @timeout = 120

      @login_status = 0
    end

#
# API Methods
#
#
# session
#
    # session.create - Create a new API session
    #
    ## Creates a new Lingr API session. Once you create a session, you must perform some API call at least once every ten minutes, or the session will time out and be automatically destroyed.
    def create_session(client_type='automaton')
      if @session
        p "already in a session", 1
        @error_info = nil
        return { :succeeded => false }
      end

      ret = do_api :post, 'session/create', { :api_key => @api_key, :client_type => client_type }, false
      @session = ret[:response]["session"] if ret[:succeeded]
      ret
    end

    # session.verify - Verify a session id.  If no session id is passed, verifies the current session id for this ApiClient
    #
    ## Verifies a Lingr API session id
    def verify_session(session_id=nil)
      do_api :get, 'session/verify', { :session => session_id || @session }, false
    end

    # session.destroy - Destroy the current API session
    #
    ## Destroys a Lingr API session
    def destroy_session
      ret = do_api :post, 'session/destroy', { :session => @session }
      @session = nil
      ret
    end

#
# authentication
#
    # auth.login - Authenticate a user within the current API session
    #
    ## Authenticates a user inside an existing API session.
    ## Some methods require the user to be logged in, while others may behave differently based on whether the user has logged in or not. Any requirements or behavioral differences related to authentication are mentioned on each methods in API reference.
    ## Only one user can login within a given session.
    def login(email, password)
      resp = do_api :post, 'auth/login', { :session => @session, :email => email, :password => password }
      if resp[:succeeded]
        @login_status = 200
      else
        @login_status = resp[:response]['status']
      end

      resp
    end

    # auth.logout - Log out the currently-authenticated user in the session, if any
    #
    def logout
      @login_status = 0
      do_api :post, 'auth/logout', { :session => @session }
    end

    def logged_in?
      [200,107].include? @login_status
    end

#
# explore
#
    # explore.getHotRooms - Get a list of the currently hot rooms
    #
    ## Gets a list of the current hot rooms.
    def get_hot_rooms(count=nil) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/get_hot_rooms', { :api_key => @api_key }.merge(count ? { :count => count} : {}), false
    end

    # explore.getNewRooms - Get a list of the newest rooms
    #
    ## Gets a list of the newest rooms.
    def get_new_rooms(count=nil) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/get_new_rooms', { :api_key => @api_key }.merge(count ? { :count => count} : {}), false
    end

    # explore.getHotTags - Get a list of the currently hot tags
    #
    ## Gets a list of the current hot tags.
    def get_hot_tags(count=nil) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/get_hot_tags', { :api_key => @api_key }.merge(count ? { :count => count} : {}), false
    end

    # explore.getAllTags - Get a list of all tags
    #
    ## Gets a list of all tags.
    def get_all_tags(count=nil) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/get_all_tags', { :api_key => @api_key }.merge(count ? { :count => count} : {}), false
    end

    # explore.search - Search room name, description, and tags for keywords.  Keywords can be a String or an Array.
    #
    ## Gets a list of the rooms matching the given search terms. For a room to appear in the results, it must match all of the search terms provided, in either the room name, room description, or room tags.
    def search(keywords) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/search', { :api_key => @api_key, :q => keywords.is_a?(Array) ? keywords.join(',') : keywords }, false
    end

    # explore.searchTags - Search room tags. Tagnames can be a String or an Array.
    #
    ## Gets a list of the rooms that have tags that match the given search terms. For a room to appear in the results, it must have tags that match all of the search terms provided.
    def search_tags(tagnames) ## !!! Do not poll this method more than once per minute.
      do_api :get, 'explore/search_tags', { :api_key => @api_key, :q => tagnames.is_a?(Array) ? tagnames.join(',') : tagnames }, false
    end

    # explore.searchArchives - Search archives. If room_id is non-nil, the search is limited to the archives of that room.
    #
    ## Gets a list of the messages from the archives that match the given search term.
    def search_archives(query, room_id=nil) ## !!! Do not poll this method more than once per minute.
      params = { :api_key => @api_key, :q => query }
      params.merge!({ :id => room_id }) if room_id
      do_api :get, 'explore/search_archives', params, false
    end

#
# user
#
    # user.getInfo - Get information about the currently-authenticated user
    #
    ## Gets information about the logged-in user in an existing API session.
    def get_user_info ## !!! Do not poll this method more than once per minute.
      do_api :get, 'user/get_info', { :session => @session }
    end

    # user.startObserving - Start observing the currently-authenticated user
    #
    ## Gets a observation ticket so that you can get notified when the information for a logged-in user of a session changes.
    def start_observing_user
      do_api :post, 'user/start_observing', { :session => @session }
    end

    # user.observe - Observe the currently-authenticated user, watching for profile changes
    #
    ## Get notified when a user’s information changes. Once you begin observing a user with user.startObserving, you must call this method at least once every two minutes, until you stop observing the user with user.stopObserving.
    ## NOTE: whenever you call user.observe, you must not do so in an HTTP session that is kept-alive from a prior call to some other API method. You may call user.observe in an HTTP session that is kept-alive from a prior call to user.observe.
    def observe_user(ticket, counter)
      do_api :get, 'user/observe', { :session => @session, :ticket => ticket, :counter => counter }
    end

    # user.stopObserving - Stop observing the currently-authenticated user
    #
    def stop_observing_user(ticket)
      do_api :post, 'user/stop_observing', { :session => @session, :ticket =>ticket }
    end

#
# room
#
#
# chat
#
    # room.enter - Enter a chatroom
    #
    ## Enter a chatroom
    def enter_room(room_id, nickname=nil, password=nil, idempotent=false)
      params = { :session => @session, :id => room_id }
      params.merge!({ :nickname => nickname }) if nickname
      params.merge!({ :password => password }) if password
      params.merge!({ :idempotent => 'true' }) if idempotent
      do_api :post, 'room/enter', params
    end

    # room.getMessages - Poll for messages in a chatroom
    #
    ## Poll a chatroom for new messages.
    ## This method is only for the case you can’t use threads in your environment.
    ## Other than that, you should always use room.observe instead.
    ## Once you enter a room with room.enter, you must call either this method or room.observe at least once every two minutes, until you exit the room with room.exit.
    ## !!! However, do not poll this method more than once per minute per ticket.
    def get_messages(ticket, counter, user_messages_only=false)
      do_api :get, 'room/get_messages', { :session => @session, :ticket => ticket, :counter => counter, :user_messages_only => user_messages_only }
    end

    # room.observe - Observe a chatroom, waiting for events to occur in the room
    #
    ## Get notified when events occur in a chatroom.
    ## Once you enter a room with room.enter, you must call either this method or room.getMessages at least once every two minutes, until you exit the room with room.exit.
    ## NOTE: whenever you call room.observe, you must not do so in an HTTP session that is kept-alive from a prior call to some other API method.
    ## You may call room.observe in an HTTP session that is kept-alive from a prior call to room.observe.
    def observe_room(ticket, counter)
      do_api :get, 'room/observe', { :session => @session, :ticket => ticket, :counter => counter }
    end

    # room.setNickname - Set your nickname in a chatroom
    #
    def set_nickname(ticket, nickname)
      do_api :post, 'room/set_nickname', { :session => @session, :ticket => ticket, :nickname => nickname }
    end

    # room.say - Say something in a chatroom.  If target_occupant_id is not nil, a private message
    # is sent to the indicated occupant.
    #
    ## Speak in a chatroom
    def say(ticket, msg, target_occupant_id = nil)
      params = { :session => @session, :ticket => ticket, :message => msg }
      params.merge!({ :occupant_id => target_occupant_id}) if target_occupant_id
      do_api :post, 'room/say', params
    end

    # room.exit - Leave a chatroom
    #
    def exit_room(ticket)
      do_api :post, 'room/exit', { :session => @session, :ticket => ticket }
    end
#
# query
#
    # room.getInfo - Get information about a chatroom, including room description, current occupants, recent messages, etc.
    #
    ## Get information about a chatroom.
    ## !!! Do not poll this method more than once per minute.
    def get_room_info(room_id, counter=nil, password=nil)
      params = { :api_key => @api_key, :id => room_id }
      params.merge!({ :counter => counter }) if counter
      params.merge!({ :password => password }) if password
      do_api :get, 'room/get_info', params, false
    end

    # room.getArchives
    #
    ## Get archived messages for a chatroom.
    ## !!! Do not polla this method more than once per minute.
    def get_room_archives(room_id, date=nil, password=nil)
      params = { :api_key => @api_key, :id => room_id }
      params.merge!({ :year => date.year, :month => date.month, :day => date.day }) if date
      # params.merge!({ :user_messages_only => user_messages_only }) if user_messages_only
      params.merge!({ :password => password }) if password
      do_api :get, 'room/get_archives', params, false
    end

#
# operation
#
    # room.create - Create a chatroom
    #
    # options is a Hash containing any of the parameters allowed for room.create.  If the :image key is present
    # in options, its value must be a hash with the keys :filename, :mime_type, and :io
    #
    ## Create a new chatroom, owned by the currently-authenticated user.
    ## !!! Currently, users are limited to owning up to 200 rooms.
    def create_room(options)
      do_api :post, 'room/create', options.merge({ :session => @session })
    end

    # room.changeSettings - Change the settings for a chatroom
    #
    # options is a Hash containing any of the parameters allowed for room.create.  If the :image key is present
    # in options, its value must be a hash with the keys :filename, :mime_type, and :io.  To change the id for
    # a room, use the key :new_id
    #
    ## Change the settings on an existing chatroom
    def change_settings(room_id, options)
      do_api :post, 'room/change_settings', options.merge({ :session => @session })
    end

    # room.delete - Delete a chatroom
    #
    ## Delete an existing chatroom.
    def delete_room(room_id)
      do_api :post, 'room/delete', { :id => room_id, :session => @session }
    end


    private

    def do_api(method, path, parameters, require_session=true)
      if require_session and !@session
        p "not in a session", 1
        return { :succeeded => false }
      end

      response = json_to_hash(self.send(method, url_for(path), parameters.merge({ :format => 'json' })))
      ret = success?(response)
      if ret
        p "#{path} succeeded", 1
      else
        p "#{path} failed : #{(response and response['error']) ? response['error']['message'] : 'socket timeout'}", 0
      end

      { :succeeded => ret, :response => response }
    end

    def url_for(method)
      "http://#{@host}/#{@@PATH_BASE}#{method}"
    end

    def get(url, params)
      uri = URI.parse(url)
      path = uri.path
      q = params.inject("?") {|s, p| s << "#{p[0].to_s}=#{CGI.escape(p[1].to_s)}&"}.chop
      path << q if q.length > 0

      begin
        Net::HTTP.start(uri.host, uri.port) { |http|
          http.read_timeout = @timeout
          req = Net::HTTP::Get.new(path)
          req.basic_auth(uri.user, uri.password) if uri.user
          parse_result http.request(req)
        }
      rescue Exception
        p "exception on HTTP GET: #{$!}", 2
        nil
      end
    end

    def post(url, params)
      if !params.find {|p| p[1].is_a?(Hash)}
        begin
          parse_result Net::HTTP.post_form(URI.parse(url), params)
        rescue Exception
          p "exception on HTTP POST: #{$!}", 2
          nil
        end
      else
        boundary = 'lingr-api-client'

        query = params.collect do |p|
          ret = "--#{boundary}\r\n"

          if p[1].is_a?(Hash)
            ret << "Content-Disposition: form-data; name=\"#{CGI::escape(p[0].to_s)}\"; filename=\"#{p[1][:filename]}\"\r\n" +
                     "Content-Transfer-Encoding: binary\r\n" +
                     "Content-Type: #{p[1][:mime_type]}\r\n" +
                     "\r\n" +
                     "#{p[1][:io].read}\r\n"
          else
            ret << "Content-Disposition: form-data; name=\"#{CGI::escape(p[0].to_s)}\"\r\n" +
              "\r\n" +
              "#{p[1]}\r\n"
          end

          ret
        end.join('') + "--#{boundary}--\r\n"

        uri = URI.parse(url)
        begin
          Net::HTTP.start(uri.host, uri.port) do |http|
              http.read_timeout = @timeout
              parse_result http.post2(uri.path, query, "Content-Type" => "multipart/form-data; boundary=#{boundary}")
          end
        rescue Exception
          p "exception on multipart POST: #{$!}", 2
          nil
        end
      end
    end

    def parse_result(result)
      return nil if !result || result.code != '200' || (!result['Content-Type'] || result['Content-Type'].index('text/javascript') != 0)
      result.body
    end

    def success?(response)
      return false if !response
      p response.inspect, 2
      response["status"] and response["status"] == 'ok'
    end

    def p(msg, level=0)
      puts msg if level <= @verbosity
    end

    def json_to_hash(json)
      return nil if !json
      return nil unless /^\s*\{\s*["']/m =~ json
      begin
        null = nil
        return eval(json.gsub(/(["'])\s*:\s*(['"0-9tfn\[{])/){"#{$1}=>#{$2}"}.gsub(/\#\{/, '\#{'))
      rescue SyntaxError
        p $!
        return nil
      else
        return nil
      end
    end

    @@PATH_BASE = 'api/'
  end
end
