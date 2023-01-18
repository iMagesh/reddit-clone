module PostsHelper
  def form_submit_tag(form, button_text)
    form.submit button_text, class: 'text-white'
  end

  def authorized_upvote(upvote)
    return upvote ? 'upvote' : 'downvote' if signed_in?

    'login'
  end

  def image_format_validation(img)
    img.to_s.include?('.png') or img.to_s.include?('.jpg')
  end

  def selected_community(community)
    return '' if params[:post] == 'new'

    community.id
  end
end
