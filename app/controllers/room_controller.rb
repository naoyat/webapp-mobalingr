#
# from Lingr API sample
#
# require 'api_client'

class RoomController < ApplicationController

  before_filter :cls

  public
#  def cookies
#    @session = session
#  end

  def cls
    @msg = ""
  end
  def puts(s=nil)
    @msg += "#{s}\n" if s
  end

  private
  def notify_error(at,response)
    render :text => "&lt;#{@ticket}&gt; #{at}: #{response.inspect}"
  end

  public
  def index
    @room_id = params[:room_id]
    unless @room_id
      redirect_to :controller => 'menu'
      return
    end

    @nickname = params[:nickname] || '' #mobalingr-bot'

    if @c
      @resp = @c.enter_room(@room_id, nil, nil, true)
      unless @resp[:succeeded]
        flash[:notice] = "room #{@room_id} not found."
        redirect_to :controller => 'menu'
        return
      end

#      @resp = @c.enter_room(@room_id, @nickname, nil, true)
      @ticket = @resp[:response]['ticket']
      @counter = -50 # 21862446
      counter = params[:cnt].to_i
      @counter = -counter if 0 < counter && counter <= 200

      if request.post? && !params[:message].blank?
        @resp = @c.set_nickname(@ticket, @nickname)
        @resp = @c.say(@ticket, params[:message])
        last_msg = {
#          'id' => ...,
          'type' => 'user',
#          'occupant_id' => ...
          'nickname' => @nickname,
          'source' => 'browser',
          'client_type' => 'human',
#          'icon_url' => ...,
          'timestamp' => Time.now.to_s,
          'text' => params[:message]
        }
      end

      last_usage = ApiUsage.last_usage_of_get_messages(@room_id, @ticket)
#      sleep (60 - last_usage.to_i) if last_usage < 60
      if last_usage >= 60
        @resp = @c.get_messages(@ticket, @counter) ## !!! once per minute per ticket
        ApiUsage.record_get_messages(@room_id, @ticket)

        session[:messages] = @messages = @resp[:response]['messages']
        flash[:notice] = nil
      else
#       flash[:notice] = "reload #{60 - last_usage.to_i} secs later to reflect your last message..."
        @resp = nil
        @messages = session[:messages]

        # reflect last message (if exists)
        if request.post? && !params[:message].blank?
          @messages << last_msg
        end
      end
    else
    end
  end

  def set_nickname
    nickname = params[:nickname]
    unless nickname
      render :text => "please specify nickname"
      return
    end

    @resp = @c.set_nickname(@ticket, nickname)
    if @resp[:succeeded]
#      puts "set_nickname succeeded : #{@resp[:response].inspect}"
    else
      notify_error "set_nickname", @resp[:response]
    end
  end

#  def pmx
#    nickname = params[:nickname]
#    message  = params[:message]
#    if message and (occupant_id = @roster.index(nickname))
#      resp = @c.say(@ticket, message, occupant_id)
#    else
#      render :text => "must supply a valid nickname and message"
#      return
#    end
#  end

#  def get_messages
#    @resp = @c.get_messages @ticket, @counter
#    if @resp[:succeeded]
#      @counter = @resp[:response]["counter"]
#      update_room_status @resp[:response]
#      render :text => "#{@counter} / #{@msg}"
#    else
#      notify_error "get_messages", @resp[:response]
#      return
#    end
#  end

  def exit
    if @ticket
#      @room_observe_thread.exit
      @c.exit_room @ticket
#      @ticket  = nil
#      @counter = nil
#      @room_observe_thread = nil
      session[:ticket] = nil
    end
#    clear_session_data
    redirect_to :controller => 'menu'
  end

  #
  def get_room_info
    room_id = params[:room_id]
    counter = params[:counter]

    @resp = @c.get_room_info(room_id,counter)
    if @resp[:succeeded]
#      @resp[:response]
      session[:room] = @room = @resp[:response]['room']
    else
      notify_error "get_room_info", @resp[:response]
      return
    end
  end

#  def verbose
#    @c.verbosity = 2
#  end
#  def quiet
#    @c.verbosity = 0
#  end

  def quit
#    @user_observe_thread.exit if @user_observe_thread
#    @room_observe_thread.exit if @room_observe_thread
    @c.destroy_session
    exit
  end

  private
  def messages_of(response)
    messages = response["messages"]
    return [] unless messages && messages.length > 0

    messages.each do |m|
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
    end if messages and messages.length > 0
  end

  def update_room_status(response)
#    updated = false
    message_of(response)
    rosters_of(response)
  end

  def rosters_of(response)
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
        @roster.each_value {|n| puts n if n }
#        puts "Room Occupants"
#        puts "=============="
        puts "#{named > 0 ? "and " : ""}#{observers} anonymous observer#{observers > 1 ? "s" : ""}" if observers > 0
      end
    end

#   updated
  end

  #
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

  #
#  def show_room_info(resp)
#    puts resp.inspect
#  end

  #
  def room_observe_loop(name)
    puts "Starting observe loop for room #{name}"
    while true
      @resp = @c.observe_room @ticket, @counter
      if @resp[:succeeded]
        @counter = @resp[:response]["counter"] if @resp[:response]["counter"]
#        print_prompt if update_room_status(@resp[:response])
      else
        puts "observe failed : #{@resp[:response].inspect}"
      end
    end
  end

  #
  def user_observe_loop(name)
    @resp = @c.start_observing_user
    puts "Couldn't observe user" and return if !@resp[:succeeded]
    user_ticket = @resp[:response]["ticket"]
    user_counter = @resp[:response]["counter"]
    puts "Starting observe loop for user #{name}"
#    print_prompt
    while true
      @resp = @c.observe_user user_ticket, user_counter
      if @resp[:succeeded]
        user_counter = @resp[:response]["counter"] if @resp[:response]["counter"]
#        print_prompt if update_user_status(resp[:response])
      else
        puts "observe_user failed : #{@resp[:response].inspect}"
      end
    end
  end

end
