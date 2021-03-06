# Usage:
#
# class MyController < ApplicationController
#   include TokenAuth
#   before_filter :validate_access
#   ...
#
#   def proposal
#     # return a Proposal
#   end
# end

module TokenAuth
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :auth_errors
  end

  def validate_access
    if !signed_in?
      authorize(:api_token, :valid!, params)
      # validated above
      sign_in(ApiToken.find_by(access_token: params[:cch]).user)
    end
    # expire tokens regardless of how user logged in
    tokens = ApiToken.joins(:approval).where(approvals: {
      user_id: current_user, proposal_id: self.proposal})
    tokens.where(used_at: nil).update_all(used_at: Time.now)

    authorize(self.proposal, :can_approve_or_reject!)
    if params[:version] && params[:version] != self.proposal.version.to_s
      raise Pundit::NotAuthorizedError.new(
        "This request has recently changed. Please review the modified request before approving.")
    end
  end

  def auth_errors(exception)
    case exception.record
    when :api_token
      session[:return_to] = request.fullpath
      if signed_in?
        flash[:error] = exception.message
        render 'authentication_error', status: 403
      else
        redirect_to root_path, alert: "Please sign in to complete this action."
      end
    when Proposal
      redirect_to proposals_path, alert: "You are not allowed to see that proposal"
    else
      flash[:error] = exception.message
      redirect_to self.proposal
    end
  end
end
