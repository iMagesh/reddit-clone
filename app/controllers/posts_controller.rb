class PostsController < ApplicationController
  before_action :authenticate_account!, except: %i[index show]
  before_action :set_community, only: %i[new show create edit update destroy increment_view_count close poll_answers]
  before_action :set_post, only: %i[show edit update destroy increment_view_count close poll_answers]
  before_action :set_draft, only: %i[new edit update]
  before_action :find_my_communities, only: %i[new create edit update ]
  before_action :community_list
  before_action :cancel_check, only: [:update]
  def index
      @posts = Post.all
  end

  def show
    increment_view_count
    @comment = Comment.new
    @categories = ReportCategory.all
    @report = Report.new
  end

  def new
    @post = @community.posts.new
  end

  def create
    @drafts = Post.drafts(current_account.id)
    @post = Post.new post_params
    @post.account_id = current_account.id
    @post.is_drafted = !(params[:commit] == 'Publish')
    if @post.save
      if @post.is_drafted?
        flash[:notice] = t('draft.success')
        redirect_to new_community_post_path(@post.community_id)
      else
        flash[:notice] = t('post.success')
        redirect_to community_path(@post.community_id)
      end
    else
      flash[:alert] = t('form.required')
      render :new
    end
  end

  def edit; end

  def update
    @post.community_id = params[:community_id]
    @post.is_drafted = !(params[:commit] == 'Publish')
    if @post.update(post_params)
      if @post.is_drafted
        flash[:notice] = t('draft.success')
        redirect_back(fallback_location: edit_community_post_path)
      else
        flash[:notice] = t('post.success')
        redirect_to community_post_path(@post.community_id)
      end
    else
      flash[:alert] = t('form.required')
      render :edit
    end
  end

  def close
    @post.update(closed: 'true')
    flash[:notice] = t('post.close')
    redirect_back(fallback_location: root_path) 
  end

  def poll_answers 
    @poll_answers=PollAnswer.new(params.permit(:poll_answer, :community_id,:post_id))
    @poll_answers.account_id = current_account.id
    if @poll_answers.save 
      flash[:notice] = t('poll_answer.create')
    else
      redirect_to root_path
    end
  end

  def my_posts
    @my_posts = @community.posts.where(account_id: current_account.id)
  end

  def destroy
    return unless @post.destroy

    flash[:notice] = t('post.destroy')
    redirect_to root_path
  end

  def post_title_search
    @posts = Post.where("title ILIKE ?", "%#{params[:search]}%")
    @communities= Community.where("name ILIKE ?", "%#{params[:search]}%")
    @accounts=Account.where("username ILIKE ?", "%#{params[:search]}%")
    @comments=Comment.where("message  ILIKE ?", "%#{params[:search]}%")
  end


  private

  def increment_view_count
    @post.view_count += 1
    @post.save
  end

  def set_community
    @community = if params[:community_id]
                   Community.friendly.includes(:posts).find(params[:community_id])
                 else
                   Community.friendly.includes(:posts).find_by(params[:community_id])
                 end
  end

  def set_draft
    @drafts = Post.drafts(current_account.id).order(created_at: :desc)
  end

  def auth_subscriber
    return if Subscription.where(community_id: params[:community_id], account_id: current_account.id).any?

    redirect_to root_path, flash: { danger: 'You are not authorized to view this page' }
  end

  def post_params
    params.require(:post).permit(:title, :body,:link, :oc, :spoiler, :nsfw, :saved, :is_drafted, :closed,
                                 :community_id,:poll_topic,:option1,:option2,:option3,:option4,images: [])
  end

  

  def find_my_communities
    @subscriptions = Subscription.where(account_id: current_account.id).pluck(:community_id)
    @my_communities = Community.find(@subscriptions)
  end

  def cancel_check
    return unless params[:commit] == 'Cancel'

    redirect_to community_post_path(@post.community_id)
  end
end
