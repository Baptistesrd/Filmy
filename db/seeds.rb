# Clear database
puts "Cleaning up database..."

WatchSession.destroy_all

# Create Watchsession
puts "Creating watch sessions..."

10.times do
  WatchSession.create!(
    title: "#{Faker::Movie.genre} Night",
    created_at: Faker::Time.backward(days: 5)
  )
end
