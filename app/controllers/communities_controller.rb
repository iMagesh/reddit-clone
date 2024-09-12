class CommunitiesController < ApplicationController
  before_action :authenticate_account!, except: [:index]
  before_action :set_community, only: %i[show edit update destroy mod]
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
    @posts = @community.posts.limit(20).sort_by { |p| p.score }.reverse
    @subscriber_count = @community.subscribers.count
    @subscribed = account_signed_in? ? Subscription.where(community_id: @community.id,account_id: current_account.id).any? : false
    @subscription = Subscription.new
    @banned_users = BannedUser.all
  end

  def new
    @community = Community.new
  end

  def edit
    if @community.account_id == current_account.id
      render :new
    else
      redirect_to communities_path, notice: t('form.forbidden')
    end
  end

  def create
    @community = Community.new community_params
    @community.account_id = current_account.id
    if @community.save
      Subscription.create!(community_id: @community.id, account_id: current_account.id)
      redirect_to @community, notice: t('community.success')
    else
      flash[:alert] = t('form.required')
      render :new
    end
  end

  def update
    if @community.update(community_params)
      redirect_to @community, notice: t('community.updated')
    else
      flash[:alert] = t('form.required')
      render :new
    end
  end

  def destroy
    @community.destroy if @community
    redirect_to communities_path, notice: t('community.destroy')
  end

  def mod
    redirect_back(fallback_location: root_path) and return unless @community.account_id == current_account.id

    @banned_user = BannedUser.where(community_id: @community.id)
                             .order(created_at: :desc)
                             .page(params[:page])
                             .per 5
    @username = Account.pluck(:username).sort
  end

  def community_post_title_search
    @community = Community.find(params[:selected_community_id])
    @posts = @community.posts.where("title ILIKE ?", "%#{params[:search]}%")
    @all_posts=Post.where(community_id: params[:selected_community_id])
    if @all_posts.present?
      @posts_with_comments = Comment.joins(:post).where("comments.message ILIKE ? and posts.id in (?)", "%#{params[:search]}%", @all_posts.pluck(:id))
    else
      @posts_with_comments = []
    end
  end

  def search_suggestions
    communities = Community.where("name ILIKE ?", "%#{params[:q]}%").select(:id, :name)
    render json: communities
  end

  def username_search
    usernames = Account.where("username ILIKE ?", "%#{params[:q]}%").select(:id , :username)
    render json: usernames
  end

  private
  def community_params
    params.require(:community).permit(:name, :url, :summary, :rules, :category, :profile_image, :cover_image)
  end

  def count_post_for_this_week
    @communities = Community.all
    @communities.each do |community|
      community.post_count_this_week = 0
      @posts = community.posts
      @posts.each do |post|
        community.post_count_this_week += 1 if ((Time.now - post.updated_at).to_f / 1.day).floor < 7
      end
      community.save
    end
  end

  def check_if_banned
    community = Community.find(params[:id])
    banned_user = BannedUser.find_by(account_id: current_account.id, community_id: community.id)
    return if banned_user.nil?

    redirect_to '/403'
  end
end
