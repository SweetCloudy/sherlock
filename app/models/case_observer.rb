class CaseObserver < ActiveRecord::Observer

  observe Case

  def after_create(model)    
    subject = model.class.to_s
    Event.create( 
      :event_type => 'create',
      :event_subtype => 'case',
      :detail_i1 => model.id,
      :user_id    => model.author_id
    )         
  end
  
  def after_destroy(model)
    subject = model.class.to_s
    Event.create( 
      :event_type => 'delete',
      :event_subtype => 'case',
      :detail_i1 => model.id,
      :user_id    => model.author_id
    )
  end  

end