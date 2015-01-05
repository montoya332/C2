module Ncr
  class ProposalForm
    include SimpleFormObject

    EXPENSE_TYPES = %w(BA61 BA80)

    BUILDING_NUMBERS = [
      'DC0017ZZ ,WHITE HOUSE-WEST WING1600 PA AVE. NW',
      'DC0027ZZ ,MAIL FACILITY2701 SOUTH CAPITOL ST.',
      'DC0035ZZ ,DWIGHT D. EISENHOWER EXECUTIVE17TH AND PA AVE. NW',
      'DC0037ZZ ,WHITE HOUSE - EAST WING1600 PA AVE., NW',
      'DC0042ZZ ,PRESIDENTS GUEST HOU1651-53 PA AVE NW',
      'DC0048ZZ ,WINDER600 SEVENTEENTH STREET',
      'DC0078ZZ ,1724 F STREET NW1724 F STREET NW',
      'DC0105ZZ ,NEW EXECUTIVE OFFICE725 17TH STREET NW',
      'Entire Jackson Place Complex',
      'DC0117ZZ ,JACKSON PL COMPLEX708 JACKSON PLACE NW',
      'DC0118ZZ ,JACKSON PL COMPLEX712 JACKSON PL NW',
      'DC0119ZZ ,JACKSON PL COMPLEX716 JACKSON PLACE NW',
      'DC0120ZZ ,JACKSON PL COMPLEX718 JACKSON PL NW',
      'DC0121ZZ ,JACKSON PL COMPLEX722 JACKSON PL NW',
      'DC0122ZZ ,JACKSON PL COMPLEX726 JACKSON PL NW',
      'DC0123ZZ ,JACKSON PL COMPLEX730 JACKSON PL NW',
      'DC0124ZZ ,JACKSON PL COMPLEX734 JACKSON PLACE NW',
      'DC0125ZZ ,JACKSON PL COMPLEX736 JACKSON PLACE NW',
      'DC0126ZZ ,JACKSON PL COMPLEX740 JACKSON PLACE NW',
      'DC0127ZZ ,JACKSON PL COMPLEX744 JACKSON PLACE NW',
      'DC0458ZZ ,REMOTE DELIVERY SITE2701 SOUTH CAPITOL ST.',
      'DC0469ZZ ,VEHICLE MAIN FAC2702 S CAPITOL ST SE',
      'DC0545ZZ ,RDS/VMF GUARDHOUSE2701 S. CAPITOL STREET',
      'Entire WH Complex',
      'Administrative Expense'
    ]
    attribute :origin, :string
    attribute :amount, :decimal
    attribute :approver_email, :text
    attribute :description, :text
    attribute :expense_type, :text
    attribute :requester, :user
    attribute :vendor, :string
    attribute :not_to_exceed, :boolean
    attribute :building_number, :string
    attribute :RWA_number, :string

    validates :amount, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 3000
    }
    validates :approver_email, presence: true
    validates :description, presence: true
    validates :expense_type, inclusion: {in: EXPENSE_TYPES}, presence: true
    validates :requester, presence: true
    validates :vendor, presence: true
    validates :building_number, presence: true

    def create_cart
      cart = Cart.new(
        flow: 'linear',
        name: self.description
      )
      if cart.save
        cart.set_props(
          origin: self.origin,
          amount: self.amount,
          expense_type: self.expense_type,
          vendor: self.vendor,
          not_to_exceed: self.not_to_exceed,
          building_number: self.building_number,
          RWA_number: self.RWA_number
        )
        cart.set_requester(self.requester)
        cart.add_approver(self.approver_email)
      end

      cart
    end
  end
end
