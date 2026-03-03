puts "Cleaning database..."
WatchSession.destroy_all
User.destroy_all

puts "Creating demo user..."
demo_user = User.create!(email: "demo@test.com", password: "123456")

puts "Creating watch sessions..."
genres = %w[Action Comedy Drama Horror Sci-Fi Thriller Romance Fantasy Crime Mystery]
moods  = %w[funny dark uplifting intense chill romantic mind-bending]

10.times do
  WatchSession.create!(
    user: demo_user,
    genre: genres.sample,
    mood: moods.sample
  )
end

puts "Done!"
