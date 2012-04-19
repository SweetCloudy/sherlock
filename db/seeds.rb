# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

admins = ['jw@mustmodify.com', 'kingeri@gmail.com', 'pebeauchemin@gmail.com']
admins.each do |e|
  User.find_or_create_by_email(
    :email => e, 
    :password => 'sherl0ckdocs40!', 
    :password_confirmation => 'sherl0ckdocs40!',
    :admin => true)
end

plans = [
  {
    :chargify_handle  => :independent,
    :cases_max        => 2,
    :extra_case_price => 5,
    :clients_max      => 10,
    :storage_max_mb   => 1024 * 2
  },
  {
    :chargify_handle  => :agency,
    :cases_max        => 10,
    :extra_case_price => 3,
    :clients_max      => 100,
    :storage_max_mb   => 1024 * 5
  },
  {
    :chargify_handle  => :corporate,
    :cases_max        => 50,
    :extra_case_price => 2,
    :clients_max      => 0,
    :storage_max_mb   => 1024 * 25
  }
]

plans.each { |plan| SubscriptionPlan.find_or_create_by_chargify_handle plan }

