puts "Cleaning database..."
Film.destroy_all
RecommendedFilm.destroy_all
Message.destroy_all
Chat.destroy_all
WatchSession.destroy_all
User.destroy_all

puts "Creating demo user..."
demo = User.create!(
  email:    "demo@filmy.io",
  password: "password123"
)

puts "Creating watch sessions..."
sessions_data = [
  { title: "Friday Night Vibes",   genre: "Thriller",  mood: "Intense",    description: "Want something that'll keep me on the edge of my seat." },
  { title: "Rainy Sunday",         genre: "Drama",     mood: "Emotional",  description: "In the mood to feel something deeply." },
  { title: "Date Night",           genre: "Romance",   mood: "Romantic",   description: "Something beautiful and grown-up." },
  { title: "Weird & Wonderful",    genre: "Sci-Fi",    mood: "Mind-bending", description: "I want my brain broken in the best way." }
]

sessions = sessions_data.map { |attrs| demo.watch_sessions.create!(attrs) }

puts "Creating chats & messages..."
sessions.first(2).each_with_index do |ws, i|
  chat = ws.chats.create!(title: "Session #{i + 1}", user: demo)

  user_msg = chat.messages.create!(
    role:    "user",
    content: "I'm in the mood for #{ws.mood.downcase} films tonight."
  )

  ai_content = <<~TEXT
    Great taste. Here are some picks for a #{ws.mood.downcase} night:

    • **The Conversation (1974)** — 113 min: Coppola's paranoid masterpiece about a surveillance expert who starts to unravel. Filmed between Godfather I and II, it's one of cinema's most overlooked gems.
    • **Oldboy (2003)** — 120 min: A man imprisoned for 15 years is released with no explanation. Park Chan-wook's revenge thriller will leave you speechless. Won the Grand Prix at Cannes.
    • **Memento (2000)** — 113 min: Nolan tells a revenge story backwards. The structure itself IS the story — a film that only works once, until it works forever.
    • **A Tale of Two Sisters (2003)** — 115 min: Korean gothic horror with an unreliable narrator that reveals itself slowly and devastatingly. The highest-grossing Korean horror film of its time.

    Refine:
    • Want more psychological or more action-driven?
    • Prefer subtitles or English-language?
    • Any runtime limit — under 100 min?
  TEXT

  ai_msg = chat.messages.create!(role: "assistant", content: ai_content)

  [
    { title: "The Conversation", year: 1974, runtime: 113, blurb: "Coppola's paranoid masterpiece about a surveillance expert who starts to unravel." },
    { title: "Oldboy",           year: 2003, runtime: 120, blurb: "A man imprisoned for 15 years is released with no explanation." },
    { title: "Memento",          year: 2000, runtime: 113, blurb: "Nolan tells a revenge story backwards." },
    { title: "A Tale of Two Sisters", year: 2003, runtime: 115, blurb: "Korean gothic horror with an unreliable narrator." }
  ].each do |film_data|
    chat.recommended_films.create!(
      watch_session: ws,
      added:         false,
      **film_data
    )
  end
end

puts "Done! Log in at demo@filmy.io / password123"
