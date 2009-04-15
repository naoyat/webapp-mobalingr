#
# = sample_chat_client.rb
#
# Lingr API sample
#
# $Revision: 35 $
# $Date: 2007-05-03 03:41:25 +0900 (木, 03  5 2007) $
#

require 'api_client'

# A simple command-line chat client that uses the Lingr API
#

module Lingr
  
  class SampleChatClient

    def initialize(key, email=nil, password=nil, hostname='www.lingr.com')
      @c = ApiClient.new(key, 0, hostname)
      @c.create_session('automaton')

      if email and password
        resp = @c.login(email, password)
        @user_observe_thread = Thread.new { user_observe_loop(email) } if resp[:succeeded]
      end
    end

    def go
      print_help
      while true
        print_prompt
        $stdin.gets
        cmd = $_.split

        case cmd[0]
          when "help", "?"
            print_help

          when "enter"
            if @ticket
              puts "already in a room"
            else
              resp = @c.enter_room(cmd[1], cmd.length > 2 ? cmd[2] : nil)
              if resp[:succeeded]
                @ticket = resp[:response]["ticket"]
                @counter = resp[:response]["room"]["counter"] if resp[:response]["room"]["counter"]
                @me = resp[:response]["occupant_id"]
                @roster = {}
                @high_counter = 0
                @room_observe_thread = Thread.new { room_observe_loop(cmd[1]) }
                update_room_status resp[:response]
              else
                puts "enter failed : #{resp[:response].inspect}"
              end
            end

          when "set_nickname"
            if cmd.length > 1
              resp = @c.set_nickname(@ticket, cmd[1])
              puts "set_nickname failed : #{resp[:response].inspect}" if !resp[:succeeded]
            else
              puts "no nickname provided"
            end

          when "say"
            if cmd.length > 1
              resp = @c.say(@ticket, cmd[1..-1].join(' '))
              puts "say failed : #{resp[:response].inspect}" if !resp[:succeeded]
            else
              puts "no message provided"
            end

          when "pmx"
            if cmd.length > 2 and (occupant_id = @roster.index(cmd[1]))
              resp = @c.say(@ticket, cmd[2..-1].join(' '), occupant_id)
            else
              puts "must supply a valid nickname and message"
            end
            
          when "get_messages"
            resp = @c.get_messages @ticket, @counter
            if resp[:succeeded]
              @counter = resp[:response]["counter"]
              puts
              update_room_status resp[:response]

            else
              puts "get_messages failed : #{resp[:response].inspect}"
            end

          when "exit"
            if @ticket
              @room_observe_thread.exit
              @c.exit_room @ticket
              @ticket = nil
              @counter = nil
              @room_observe_thread = nil
            end

          when "get_room_info"
            resp = @c.get_room_info(cmd[1], cmd[2])
            if resp[:succeeded]
              show_room_info resp[:response]
            else
              puts "get_room_info failed : #{resp[:response].inspect}"
            end

          when "verbose"
            @c.verbosity = 2

          when "quiet"
            @c.verbosity = 0

          when "quit"
            @user_observe_thread.exit if @user_observe_thread
            @room_observe_thread.exit if @room_observe_thread
            @c.destroy_session
            break

          else
            puts "unrecognized command #{cmd[0]}" if cmd[0]
        end
      end
    end

    private

    def update_room_status(response)
      updated = false

      if response["messages"] and response["messages"].length > 0
        response["messages"].each do |m|
          next if m["id"] and m["id"].to_i <= @high_counter
          
          text = m["text"]
          type = m["type"]

          if type == 'user' or type == 'private'
            occupant_id = m["occupant_id"]
            if occupant_id != @me or type == 'private'
              updated = true
              nickname = m["nickname"]
              if type == 'private'
                puts "PRIVATE MESSAGE from #{nickname}: #{text}"
              else
                puts "#{nickname} says: #{text}"
              end
            end
          elsif type.index('system:') == 0
            updated = true
            puts "SYSTEM: #{text}"
          else
            puts "unknown message type: #{type}, #{text}"
          end
          
          @high_counter = m["id"].to_i if m["id"]
        end
      else
        puts
      end

      roster_present = !response["occupants"].nil?
      new_roster = {}

      observers = 0
      named = 0

      if roster_present
        response["occupants"].each do |o|
          new_roster[o["id"]] = o["nickname"]
          if !o["nickname"].nil?
            named += 1
          else
            observers += 1
          end
        end

        if roster_present and @roster != new_roster
          updated = true
          @roster = new_roster

          puts

          puts "Room Occupants"
          puts "=============="
          @roster.each_value {|n| puts n if n }
          puts "#{named > 0 ? "And " : ""}#{observers} anonymous observer#{observers > 1 ? "s" : ""}" if observers > 0
        end
      end

      updated
    end

    def update_user_status(response)
      if response["email"]
        puts
        puts "User was updated"
        puts "================"
        puts "email: #{response["email"]}"
        puts "default nickname: #{response["default_nickname"]}"
        puts "#{response["owned_rooms"].length} owned rooms" if response["owned_rooms"]
        puts "#{response["favorite_rooms"].length} favorite rooms" if response["favorite_rooms"]
        puts "#{response["visited_rooms"].length} visited rooms" if response["visited_rooms"]
        puts "#{response["monitored_rooms"].length} monitored rooms" if response["monitored_rooms"]
        puts "#{response["occupied_rooms"].length} occupied rooms" if response["occupied_rooms"]
      end

      true
    end

    def show_room_info(resp)
      puts resp.inspect
    end

    def room_observe_loop(name)
      puts "Starting observe loop for room #{name}"
      while true
        resp = @c.observe_room @ticket, @counter
        if resp[:succeeded]
          @counter = resp[:response]["counter"] if resp[:response]["counter"]
          print_prompt if update_room_status(resp[:response])
        else
          puts "observe failed : #{resp[:response].inspect}"
        end
      end
    end

    def user_observe_loop(name)
      resp = @c.start_observing_user
      puts "Couldn't observe user" and return if !resp[:succeeded]
      user_ticket = resp[:response]["ticket"]
      user_counter = resp[:response]["counter"]
      puts "Starting observe loop for user #{name}"
      print_prompt
      while true
        resp = @c.observe_user user_ticket, user_counter
        if resp[:succeeded]
          user_counter = resp[:response]["counter"] if resp[:response]["counter"]
          print_prompt if update_user_status(resp[:response])
        else
          puts "observe_user failed : #{resp[:response].inspect}"
        end
      end
    end

    def print_help
      puts "enter <room_id> [nickname]"
      puts "set_nickname <nickname>"
      puts "say <message>"
      puts "pmx <nickname> <message>"
      puts "get_messages"
      puts "exit"
      puts "get_room_info <room_id> [<counter>]"
      puts "verbose"
      puts "quiet"
      puts "quit"
    end

    def print_prompt
      print "> "
      $stdout.flush
    end
  end

  if ARGV.length == 0
    puts "usage: simple_chat_client <api_key> [email password host]"
  else
    SampleChatClient.new(ARGV[0], ARGV[1], ARGV[2], ARGV[3] || 'www.lingr.com').go
  end

end
