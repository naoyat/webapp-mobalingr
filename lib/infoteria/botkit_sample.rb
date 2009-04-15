#
# = botkit_sample.rb
#
# Lingr Botkit
#
# $Revision: 18 $
# $Date: 2007-02-09 06:42:48 +0900 (金, 09  2 2007) $
#
# Copyright (c) 2007 Infoteria USA.
# You can redistribute it and/or modify it under the same terms as Ruby.
#
# Author:: Satoshi NAKAGAWA
#
# == Overview
#
# This is a working sample, 'DiceBot'.
# 

require 'botkit'

class DiceBot < Lingr::BotBase
  def initialize(c)
    @c = c
  end
  
  def on_init
    puts '*** Initialized (CTRL-C to quit)'
  end

  def on_text(room, mes)
    puts "#{room.name} > #{mes.nickname}: #{mes.text}"
    if mes.text.match(/^((\d+)[Dd](\d+)(?:\+(\d+))?)$/) and $2.to_i > 0 and $3.to_i > 0
      dices = []
      sum = 0
      msg = ''
      $2.to_i.times do |i|
        dice = rand($3.to_i) + 1
        dices.push(dice)
        sum += dice
      end
      msg << (sum + ($4 || '0').to_i).to_s << ' = ' << dices.join(' + ')
      msg << ' ( + ' << $4 << ' )' if $4
      msg << ' ... ' << $1
      room.say msg
    end
  end

  def on_bot_text(room, mes)
    puts "#{room.name} > (#{mes.nickname}): #{mes.text}"
  end

  def on_enter(room, mes)
    puts "#{room.name} > *** #{mes.nickname} has joined the conversation"
  end

  def on_leave(room, mes)
    puts "#{room.name} > *** #{mes.nickname} has left the conversation"
  end

  def on_nickname_change(room, mes)
    puts "#{room.name} > *** #{mes.nickname} is now known as #{mes.new_nickname}"
  end
end

def main
  api_key = 'write your api key here'
  rooms = [{ :id => 'write room id you want to enter' }, { :id => '...', :password => '...' }]
  nickname = 'DiceBot'
  c = Lingr::LingrClient.new(api_key)
  c.bot = DiceBot.new(c)
  c.open do
    rooms.each do |r|
      c.enter_room r[:id], nickname, r[:password]
    end
    c.enter_event_loop
    rooms.each do |r|
      c.exit_room r[:id]
    end
  end
end

main
