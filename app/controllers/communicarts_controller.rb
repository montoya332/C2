class CommunicartsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def send_cart
    Cart.initialize_cart_with_items(params)

    approval_group_name = params['approvalGroup']


    sum = params['cartItems'].reduce(0) do |sum,value|
      sum + (value["qty"].gsub(/[^\d\.]/, '').to_f *  value["price"].gsub(/[^\d\.]/, '').to_f)
    end
    params['totalPrice'] = "%0.2f" % sum


    if !approval_group_name.blank?
      approval_group = ApprovalGroup.find_by(name: approval_group_name)

      approval_group.approvers.each do | approver |
        CommunicartMailer.cart_notification_email(approver.email_address,params).deliver
      end
    else
      CommunicartMailer.cart_notification_email(params["email"],params).deliver
    end
    render json: { message: "This was a success"}, status: 200
  end

  def approval_reply_received
    cart = Cart.find_by(external_id: (params['cartNumber'].to_i))
    cart.decorate

    approver = cart.approval_group.approvers.where(email_address: params['fromAddress']).first
    approver.update_attributes(status: approve_or_disapprove_status)
    cart.update_approval_status

    cart_report = EmailStatusReport.new(cart)
    CommunicartMailer.approval_reply_received_email(params, cart_report).deliver
    render json: { message: "approval_reply_received"}, status: 200
  end

  def approve_or_disapprove_status
    #TODO: Refactor duplication with ComunicartMailer#approval_reply_received_email
    params["approve"] == "APPROVE" ? "approved" : "disapproved"
  end
end
