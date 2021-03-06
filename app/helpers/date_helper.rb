module DateHelper

  def format_day(t)
    if t.nil?
      '-'
    else
      t.in_time_zone('EST').strftime('%m/%d/%Y')
    end
  end
  
  def format_date(t)
    if t.nil?
      '-'
    else
      t.in_time_zone('EST').strftime('%m/%d/%Y %H:%M %Z')
    end
    
  end
  
end
