class AccountsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :authorize_pi!

  def show
    @account = current_user
    @account.user_address ||= @account.init_address 
    
    @my_subscription  = current_user.current_subscription
    @my_plan          = current_user.current_plan
    @one_time_credits = current_user.unused_purchases
    
    @cases = current_user.authored_cases
    
  end

  def update
    
    # remove password / password confirmation if blank
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    @account = current_user

    if( @account.update_attributes( params[:user] ))
      notice = "Information Updated"
      redirect_to dashboard_path, :notice => notice
    else
      render :action => 'show'
    end
  end
end

