#
# = botkit.rb
#
# Lingr Botkit
#
# $Revision: 31 $
# $Date: 2007-04-13 19:05:27 +0900 (金, 13  4 2007) $
#
# Copyright (c) 2007 Infoteria USA.
# You can redistribute it and/or modify it under the same terms as Ruby.
#
# Author:: Satoshi NAKAGAWA
#
# == Overview
#
# Botkit is a kit for building a bot on the Lingr API.
# See also botkit_sample.rb for a working example.
#
# == How to use Botkit
#
# Make your bot class inherited from the +BotBase+ class.
#
#  require 'botkit'
#  
#  class HelloBot < Lingr::BotBase
#    def on_init
#      puts '*** Initialized (CTRL-C to quit)'
#    end
#  
#    def on_text(room, mes)
#      puts "#{room.name} > #{mes.nickname}: #{mes.text}"
#      if mes.text.match(/hello/i)
#        room.say "Hello #{speaker.nickname}"
#      end
#    end
#  
#    def on_bot_text(room, mes)
#      puts "#{room.name} > (#{mes.nickname}): #{mes.text}"
#    end
#  
#    def on_enter(room, mes)
#      puts "#{room.name} > *** #{mes.nickname} has joined the conversation"
#    end
#    
#    def on_leave(room, mes)
#      puts "#{room.name} > *** #{mes.nickname} has left the conversation"
#    end
#    
#    def on_nickname_change(room, mes)
#      puts "#{room.name} > *** #{mes.nickname} is now known as #{mes.new_nickname}"
#    end
#  end
#
# And write as bellow in the global context.
#
#  def main
#    api_key = 'write your api key here'
#    room = 'write room id you want to enter'
#    nickname = 'HelloBot'
#    c = Lingr::LingrClient.new(api_key)
#    c.bot = HelloBot.new
#    c.open do
#      c.enter_room room, nickname
#      c.enter_event_loop
#      c.exit_room room
#    end
#  end
#  main
#

require 'api_client'
require 'thread'
require 'time'

module Lingr

  # Exception class for quit.
  class LingrClient_QuitProgram < Exception; end
  
  # Message model class.
  #
  # Wraps a text or system message sent from the server.
  class Message
    attr_reader :id, :type, :timestamp, :occupant_id, :user_id, :nickname, :new_nickname, :source, :client_type, :icon_url, :text
    def initialize(id, type, timestamp, occupant_id, user_id, nickname, new_nickname, source, client_type, icon_url, text)
      @id = id
      @type = type
      @timestamp = Time.parse timestamp
      @occupant_id = occupant_id
      @user_id = user_id
      @nickname = nickname
      @new_nickname = new_nickname
      @source = source
      @client_type = client_type
      @icon_url = icon_url
      @text = text
    end
  end

  # Room occupant model class.
  #
  # Wraps an occupant in a room.
  # A Room has many Occupants.
  class Occupant
    attr_reader :id, :user_id, :nickname, :desc, :icon_url, :source, :client_type
    def initialize(id, user_id, nickname, desc, icon_url, source, client_type)
      @id = id
      @user_id = user_id
      @nickname = nickname
      @desc = desc
      @icon_url = icon_url
      @source = source
      @client_type = client_type
    end
  end

  # Room model class.
  #
  # Wraps room information.
  # Owned by a RoomClient.
  class Room
    attr_reader :id, :name, :desc, :url, :icon_url, :occupants
    attr_accessor :max_user_message_id
    def initialize(id, name, desc, url, icon_url, max_user_message_id)
      @id = id
      @name = name
      @desc = desc
      @url = url
      @icon_url = icon_url
      @max_user_message_id = max_user_message_id
      @occupants = []
    end

    def add_occupant(occupant)
      occupants << occupant
    end

    def remove_occupant(id)
      delete_if {|i| i.id == id}
    end

    def find_occupant(id)
      occupants.find {|i| i.id == id}
    end

    def clear_occupants
      @occupants = []
    end
  end

  # Room controller class.
  #
  # Wraps room observing thread.
  # And this class also exports model information.
  # A LingrClient has many RoomClients.
  class RoomClient
    attr_reader :id, :nickname, :occupant_id

    def initialize(parent, id, nickname=nil, password=nil)
      @p = parent
      @id = id
      @nickname = nickname
      @password = password
    end

    # Enter a room (with +nickname+).
    def enter
      result = @p.c.enter_room(@id, @nickname, @password)
      return nil if !result || !result[:succeeded]
      res = result[:response]
      room = res['room']
      @ticket = res['ticket']
      @occupant_id = res['occupant_id']
      @counter = room['counter']
      @room = Room.new(room['id'], room['name'], room['description'], room['url'], room['icon_url'], room['max_user_message_id'])
      parse_occupants res['occupants']
      @monitor_thread = Thread.new { observe_loop }
    end

    # Exit the room.
    def exit
      begin
        @monitor_thread.kill if @monitor_thread
      rescue Exception => e
      end
      @p.c.exit_room(@ticket)
      @ticket = nil
    end

    # Change your nickname.
    def set_nickname(to_nick)
      res = @p.c.set_nickname(@ticket, to_nick)
      @nickname = to_nick
    end

    # Send a text message.
    def say(text)
      res = @p.c.say(@ticket, text)
    end

    def name
      @room.name
    end

    def desc
      @room.desc
    end

    def url
      @room.url
    end

    def icon_url
      @room.icon_url
    end

    def occupants
      @room.occupants
    end
    
    def max_user_message_id
      @room.max_user_message_id
    end
    
    def max_user_message_id=(new_id)
      @room.max_user_message_id = new_id
    end

    def add_occupant(occupant)
      @room.add_occupant occupant
    end

    def remove_occupant(id)
      @room.remove_occupant id
    end

    def find_occupant(id)
      @room.find_occupant id
    end

    def clear_occupants
      @room.clear_occupant
    end

    private

    def observe_loop
      while true
        begin
          result = @p.c.observe_room(@ticket, @counter)
          if !result || !result[:succeeded]
            errcode = result[:response]['error']['code'] if result[:response]
            if errcode
              errmsg = result[:response]['error']['message']
              case errcode
              when 102,109
                puts "Error on room.observe: #{errcode} #{errmsg}"
                break
              end
            end
            sleep 30
            next
          end
          res = result[:response]
          old_counter = @counter.to_i
          @counter = res['counter'] if res['counter']
          parse_occupants res['occupants']
          messages = res['messages']
          if messages
            messages.each do |m|
              mes = Message.new(m['id'], m['type'], m['timestamp'], m['occupant_id'], m['user_id'], m['nickname'], m['new_nickname'], m['source'], m['client_type'], m['icon_url'], m['text'])
              if mes.id.to_i > old_counter
                @p.q << { :room => self, :message => mes }
              end
            end
          end
        rescue Exception => e
          puts 'Exception in observe_loop: ' + e.to_s
          sleep 30
        end
      end
      puts 'Quiting observe_loop'
    end

    def parse_occupants(occupants)
      if occupants
        @room.clear_occupants
        occupants.each do |i|
          @room.add_occupant Occupant.new(i['id'], i['user_id'], i['nickname'], i['description'], i['icon_url'], i['source'], i['client_type'])
        end
      end
    end

  end

  # Client controller class.
  #
  # Wraps a primary connection for Lingr API.
  class LingrClient
    attr_reader :c, :q, :hostname, :password, :rooms
    attr_accessor :bot

    def initialize(key, email=nil, password=nil, hostname='www.lingr.com')
      @email = email
      @password = password
      @hostname = hostname
      @c = ApiClient.new(key, 0, @hostname)
      @rooms = []
      @q = Queue.new
    end

    # Open an automaton session.
    def open
      if block_given?
        open
        begin
          yield
        ensure
          close
        end
      else
        @c.create_session('automaton')
      end
    end

    # Close the session.
    def close
      begin
        @c.destroy_session
      rescue Exception => e
      end
    end

    # Log in.
    def login
      @c.login(@email, @password)
    end

    # Log out.
    def logout
      @c.logout
    end

    # Enter a room (with +nickname+ and +password+) and add it to the room list.
    def enter_room(id, nickname=nil, password=nil)
      room = RoomClient.new(self, id, nickname, password)
      @rooms << room
      room.enter
    end

    # Exit the room and remove it from the room list.
    def exit_room(id)
      room = find_room(id)
      if room
        room.exit
        @rooms.delete_if {|i| i.id == id}
      end
    end

    # Change your +nickname+ in the room.
    def set_nickname(id, to_nickname)
      room = find_room(id)
      if room
        room.set_nickname(to_nickname)
      end
    end

    # Send a text message to the room.
    def say(id, text)
      room = find_room(id)
      if room
        room.say(text)
      end
    end
    
    # Find a room in the room list.
    def find_room(id)
      @rooms.find {|i| i.id == id}
    end

    # Enter the event loop.
    #
    # In this loop wait messages from the server.
    # When new messages are received, dispatch these messages to callback methods in the bot.
    # To exit this loop, call exit_event_loop.
    def enter_event_loop
      set_signal_trap
      begin
        @bot.on_init if @bot
        while true
          res = @q.pop
          break if !res
          if @bot
            room = res[:room]
            mes = res[:message]
            case mes.type
            when 'user'
              room.max_user_message_id = mes.id if room
              if mes.client_type == 'human'
                @bot.on_text room, mes
              else
                @bot.on_bot_text room, mes
              end
            when 'system:enter'
              @bot.on_enter room, mes
            when 'system:leave'
              @bot.on_leave room, mes
            when 'system:nickname_change'
              @bot.on_nickname_change room, mes
            end
          end
        end
      rescue LingrClient_QuitProgram
        puts 'Quiting event loop...'
      end
    end
    
    # Exit the event loop.
    def exit_event_loop
      @q << nil
    end

    private

    def set_signal_trap
      list = Signal.list.keys
      Signal.trap(:INT) {
        Thread.main.raise LingrClient_QuitProgram
      } if list.any? {|e| e == 'INT'}
      Signal.trap(:TERM) {
        Thread.main.raise LingrClient_QuitProgram
      } if list.any? {|e| e == 'TERM'}
    end

  end

  # Base class of bots.
  #
  # When you write your bot, inherit this class.
  class BotBase
    # Called after initialization of the event loop.
    def on_init
    end
    
    # Called when a text message is received.
    def on_text(room, mes)
    end

    # Called when a text message from automaton is received.
    def on_bot_text(room, mes)
    end
    
    # Called when an enter system message is received.
    def on_enter(room, mes)
    end
    
    # Called when a leave system message is received.
    def on_leave(room, mes)
    end
    
    # Called when a nickname_change message is received.
    def on_nickname_change(room, mes)
    end
  end

end
