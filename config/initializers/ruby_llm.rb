RubyLLM.configure do |config|
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.openai_api_key    = ENV["OPENAI_API_KEY"]
end
