puts "Cleaning database..."

WatchSession.destroy_all
User.destroy_all

puts "Creating demo user..."

demo_user = User.create!(
  email: "demo@test.com",
  password: "123456"
)

puts "Creating watch sessions..."

10.times do
  WatchSession.create!(
    user: demo_user,
    title: "#{Faker::Book.genre} Night",
    created_at: Faker::Time.backward(days: 5)
  )
end

puts "Done!"
