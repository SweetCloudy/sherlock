class BlockTypes::PageBreak < ActiveRecord::Base
  
  include BlockDetail
  
  belongs_to :block 
  
  after_save :invalidate_report
  
  attr_accessible :with_header
  
  def as_json(options = {})
    postprocess(super(options))
  end
  
  def author
    kase.author
  end
  
  def letterhead
    author.letterhead
  end
  
  def kase
    block.case
  end      
  
  def postprocess(json)   
    json.merge('withHeader' => json['with_header'])
  end
  
end
