require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Letterhead do
  
  it 'JSON should return proper textAlign' do
    user = User.new() { |u| u.id = 1}
    letterhead = Letterhead.new(
      :user       => user,
      :text_align => :left
    )    
    decoded = ActiveSupport::JSON.decode(letterhead.to_json(:camelize => true))    
    decoded['textAlign'].to_s.should == 'left'            
  end
  
  it 'JSON should contain divider settings' do
    user = User.new() { |u| u.id = 1}
    letterhead = Letterhead.new(
      :user           => user,
      :divider_above  => true,
      :divider_size   => 10,
      :divider_width  => 75,
      :divider_color  => :blue
    )    
    decoded = ActiveSupport::JSON.decode(letterhead.to_json(:camelize => true))    
    decoded['divider']['height'].should == 10
  end
  
end
