class AccountController < ApplicationController

#  def index
#  end

  # sign in
  def login
    @title = "mobaLingr > Sign In"
    if request.post?
      e = params[:email]
      p = params[:password]
      if e.blank? or p.blank?
        @flash[:notice] = 'please enter email/password'
        render
        return
      end

      @c.login(e, p)
      if @c.logged_in?
        # login succeeded
        if params[:keep].to_i == 1
          if @user
            @user.email = e
            @user.password = p
            @user.save # = User.valid_user(e, p)
          else
            @user = User.create(:email => e, :password => p)
          end
        end

        if ApiUsage.get_user_info_available?
          resp = @c.get_user_info # !!! once per minute
          ApiUsage.record_get_user_info

          if resp && resp[:succeeded]
            response = resp[:response]

            @user.update_attributes(:icon_url => response['icon_url'],
                                    :email => response['email'],
                                    :counter => response['counter'],
                                    :user_id => response['user_id'],
                                    :default_nickname => response['default_nickname'],
                                    :description => response['description'] )
            @user.visited_rooms   = response['visited_rooms'].rooms
            @user.favorite_rooms  = response['favorite_rooms'].rooms
            @user.owned_rooms     = response['owned_rooms'].rooms
            @user.monitored_rooms = response['monitored_rooms'].rooms
            @user.occupied_rooms  = response['occupied_rooms'].rooms
          else
#            session[:visited_rooms]   = nil
#            session[:favorite_rooms]  = nil
#            session[:owned_rooms]     = nil
#            session[:monitored_rooms] = nil
#            session[:occupied_rooms]  = nil
          end
          session[:user] = @user
        else
          # cannot access API user.getInfo
          session[:user] = @user
        end
        redirect_to :controller => 'menu'
        return
      else
        # login failed
        @flash[:notice] = 'login failed'
      end
    end
  end

  # sign out
  def logout
    @c.logout if @c.logged_in?

    session[:user]            = nil
    session[:visited_rooms]   = nil
    session[:favorite_rooms]  = nil
    session[:owned_rooms]     = nil
    session[:monitored_rooms] = nil
    session[:occupied_rooms]  = nil

    redirect_to :controller => 'menu' #, :action => 'index'
  end

  # sign up
  def signup
  end

end
