class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :set_watch_sessions, if: :user_signed_in?

  private

  def set_watch_sessions
    @watch_sessions = current_user.watch_sessions.order(created_at: :desc)
  end
end
