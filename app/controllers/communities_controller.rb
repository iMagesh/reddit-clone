class CommunitiesController < ApplicationController
  before_action :authenticate_account!, except:  [ :index]
  before_action :set_community, only: [:show, :edit,:update,:destroy]
  before_action :community_list
  before_action :check_if_banned, only: [:show]
  after_action :count_post_for_this_week, only: [:index]
  

  def index
    count_post_for_this_week
    @categories = Community::CATEGORIES 
    if(params.has_key?(:category))
      @communities = Community.where(category: params[:category]).order(created_at: :desc).page(params[:page]).per 7
    else
      @communities = Community.order(created_at: :desc).page(params[:page]).per 7
    end
    @random_category_communities = Community.where(category: @categories.sample).order("post_count_this_week desc").limit(5)
  end

  def show
    @community = Community.find(params[:id])
    @posts = @community.posts.limit(20).sort_by{ |p| p.score }.reverse
    @subscriber_count = @community.subscribers.count
    @is_subscribed = account_signed_in? ? Subscription.where(community_id: @community.id, account_id: current_account.id).any? : false
    @subscription = Subscription.new
    @banned_users = BannedUser.all
  end

  def new
    @community = Community.new
  end

  def edit

  end

  def create
    @community = Community.new community_values
    @community.account_id = current_account.id
    @community.owner_id = current_account.id 
    if @community.save
      redirect_to communities_path
    else
      render :new
    end
  end

  def update
    if @community.update(community_values)
      redirect_to @community
    else
      render :new
    end
  end

  def destroy
    @community.destroy if @community
    redirect_to communities_path
  end

  def mod
    @banneduser = BannedUser.new
    @username = Account.pluck(:username).sort
  end 

  def usernames
    query = params[:username]
    usernames = Account.where("username LIKE ?", "%#{username}%").pluck(:username)
    render json: usernames
  end

  private
  def set_community
    @community = Community.find(params[:id])
  end

  def community_values
    params.require(:community).permit(:name, :url, :summary, :rules, :category, :profile_image, :cover_image)
  end

  def count_post_for_this_week
    @communities = Community.all
    @communities.each do |community|
      community.post_count_this_week = 0
      @posts = community.posts
      @posts.each do |post|
        if ((Time.now - post.updated_at).to_f / 1.day).floor < 7
          community.post_count_this_week += 1
        end
      end
      community.save
    end
  end

  def check_if_banned
    community = Community.find(params[:id])
    puts current_account.id
    banned_user = BannedUser.find_by(account_id: current_account.id, community_id: community.id)
    unless banned_user.nil?
      redirect_to '/404'
    end
  end

end
