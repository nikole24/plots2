class SubscriptionMailer < ActionMailer::Base
  default from: "do-not-reply@publiclab.org"

  # SubscriptionMailer.notify(user,self).deliver 
  def notify_node_creation(node)
    # figure out who needs to get an email, no dupes
    subject = "[PublicLab] " + node.title
    get_tag_subscribers(node).each do |key,val|
      @user = val[:user]
      @node = node
      @tags = val[:tags]
      mail(:to => val[:user].email, :subject => subject)
    end
  end

  private

  # Return all users subscribed to the given node as keys to a dictionary of
  # sets, each set contains a reference to the node.
  def get_node_subscribers(node)
    users = NodeSelection.find_by_nid_and_following(node.nid, true)
    d = {}
    users.each do |user|
      d[user] = [node].to_set
    end
    return d
  end

  # Fetch all the tag ids associated with a node.
  def get_node_tags(node)
    # find all tags for the node
    # Currently tag names and tids aren't 1:1 even though they are supposed to be; there are duplicates. 
    # Rewrite tag creation code and migrate to eliminate this,
    # but in the meantime, search tags by tagname, not tid
    tids = []
    node.tagnames.each do |tagname|
      # sadly, Drupal has 2 different tag tables. 
      # We are only using "community_tags" but have to include the other for legacy support
      tids += DrupalTag.find_all_by_name(tagname).collect(&:tid)
    end
    tids
  end

  # Given a node, find all tags for that node and then all users following
  # that tag. Return a dictionary of tags indexed by user.
  def get_tag_subscribers(node)
    tids = get_node_tags(node)
    usertags = TagSelection.find(:all, :conditions => ["tid IN (?) AND following = true",tids])
    d = {}
    usertags.each do |usertag|
      # For each row of (user,tag), build a user's tag subscriptions 
      d[usertag.user.name] = {:user => usertag.user}
      d[usertag.user.name][:tags] = Set.new if d[usertag.user.name][:tags].nil?
      d[usertag.user.name][:tags].add(usertag.tag)
    end
    return d
  end
end
