User.destroy_all # will delete all users and all their tweets

20.times do |i|
  user = Fabricate(:user)
  rand(10).times do
    Fabricate(:tweet, user: user)
  end
  puts "Generated #{user.name} with #{user.tweets.count} tweets"
end
