class Invitation < Valuable
  extend ActiveModel::Naming
  include ActiveModel::Conversion # required for forms
  include ActiveModel::Validations

  has_value :email
  has_value :name
  has_value :message
  has_value :case_id
  
  attr_writer :url_invitation
  attr_writer :url_cases 
  
  attr_accessor :current_user

  validates :email, :email => true
  validates_presence_of :email, :name, :message, :case_id
  
  validate :receipient_is_not_me

  def to_model
    self
  end

  def persisted?() false end
  def new_record?() true end
  def destroyed?()  true end

  def case
    Case.find self.case_id
  end

  def deliver 
    valid? && find_or_create_guest && set_permissions && deliver_email
  end
   
  def guest
    find_or_create_guest
  end
  
  private
  
  def receipient_is_not_me
    errors.add(:email, 'must be different from your email') if 
      email.present? && email == current_user.email          
  end
  
  def find_or_create_guest 
    @guest ||= User.where(:email => self.email).first || 
         User.invite!(:email => self.email, 
                      :name => self.name, 
                      :skip_invitation => true)
  end

  def set_permissions
    self.case.viewers << guest unless (self.case.author == guest)
  end

  def deliver_email
    PostOffice.invitation(with_presentation_layer).deliver
  end
  
  def with_presentation_layer
    if self.guest.invited?
      IntroductoryInvitationPresenter.new(self, url_invitation)
    else
      RepeatInvitationPresenter.new( self, url_cases )
    end
  end
end

