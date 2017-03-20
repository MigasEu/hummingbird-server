class CommentPolicy < ApplicationPolicy
  include GroupPermissionsHelpers

  def update?
    return true if is_admin?
    return true if group && has_group_permission?(:content)
    return false if record.created_at&.<(30.minutes.ago)
    is_owner?
  end

  def create?
    return false unless user
    return false if user.unregistered?
    return false if user.blocked?(record.post.user)
    return false if user.has_role?(:banned)
    return false if group && !member?
    is_owner?
  end

  def destroy?
    return true if group && has_group_permission?(:content)
    is_owner? || is_admin?
  end

  def editable_attributes(all)
    all - [:content_formatted]
  end

  def group
    record.post.target_group
  end

  class Scope < Scope
    def resolve
      scope.where.not(user_id: blocked_users)
    end
  end
end
