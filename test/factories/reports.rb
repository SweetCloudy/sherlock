FactoryGirl.define do
  factory :report do 
    association :case
    title { String.random(10) }
    output_file 'file.mov'
  end
end

