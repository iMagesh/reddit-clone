class CommentsController < ApplicationController
  before_action :set_post, only: [:create]

  def create
    @comment = @post.comments.build comment_params
    @comment.account_id = current_account.id
    if @comment.save
      flash[:notice] = t("comment.create")
    else
      flash[:alert] = t("comment.empty")
    end
   
    Comment.all.each do |comment|
      string_text = comment.message.to_s
      string_t = string_text.gsub(/<[^>]*>/, "").gsub(/\n/, "")
      Comment.where(id: comment.id).update_all(message: string_t)
    end  
    redirect_to community_post_path(@comment.post.community_id, @comment.post)
  end

  def comment_params
    params.require(:comment).permit(:message, :replies, :parent, :parent_id)
  end

end
