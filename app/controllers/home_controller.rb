class HomeController < ApplicationController
  skip_before_filter :require_activation
  
  def index
    @topics = Topic.find_recent
    @members = Person.find_recent
    if logged_in?
      @body = "home"
      @person = current_person
      @requested_memberships = current_person.requested_memberships
      @invitations = current_person.invitations
      if params[:mode]
        @reqs = current_person.current_and_active_reqs
        @bids = current_person.current_and_active_bids
        @offers = current_person.current_offers
      else
        @feed = Activity.exchange_feed
      end
    else
      @body = "blog"
    end    
  end

  def show
    @post = FeedPost.find(params[:id])
  end

  def refreshblog
    new_posts_count = FeedPost.update_posts
    if nil == new_posts_count
      flash[:error] = "Blog update failed."
    else
      flash[:notice] = "Blog updated #{new_posts_count} entries."
    end
    redirect_to '/home' 
  end
end
