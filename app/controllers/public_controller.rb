class PublicController < ApplicationController
  def index
    @communities = Community.order("post_count_this_week desc").limit(5)
    @posts = Post.order(created_at: :desc).page(params[:page]).per 5
    @top_posts = Post.order(view_count: :desc).page(params[:page]).per 5
    @new_posts = Post.order(created_at: :desc).page(params[:page]).per 5
    @hot_posts = Post.order(view_count: :desc).page(params[:page]).per 5
  end
  def profile
    community_list
    
    @subscriptions = Subscription.where(account_id: current_account.id)
    @community = Community.find(@subscriptions.pluck(:community_id))
    @my_communities = Community.where(account_id: current_account.id)
    @profile = Account.find_by_username params[:username]
    @posts = @profile.posts
  end
end
