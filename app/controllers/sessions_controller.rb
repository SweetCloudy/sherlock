class SessionsController < Devise::SessionsController
  
  def destroy
    if current_user
      Kissmetrics.init_and_identify(current_user.id)      
      KM.record('Signed Out')
    end
    super
  end
  
end
