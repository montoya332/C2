describe Ncr::WorkOrder do
  describe 'fields_for_display' do
    it "shows BA61 fields" do
      wo = Ncr::WorkOrder.new(
        amount: 1000, expense_type: "BA61", vendor: "Some Vend",
        not_to_exceed: false, emergency: true, rwa_number: "RWWAAA #",
        building_number: Ncr::BUILDING_NUMBERS[0],
        office: Ncr::OFFICES[0], description: "Ddddd")
      expect(wo.fields_for_display.sort).to eq([
        ["Amount", 1000],
        ["Building number", Ncr::BUILDING_NUMBERS[0]],
        ["Description", "Ddddd"],
        ["Emergency", true],
        ["Expense type", "BA61"],
        ["Not to exceed", false],
        ["Office", Ncr::OFFICES[0]],
        # No RWA Number
        ["Vendor", "Some Vend"]
        # No Work Order
      ])
    end
    it "shows BA80 fields" do
      wo = Ncr::WorkOrder.new(
        amount: 1000, expense_type: "BA80", vendor: "Some Vend",
        not_to_exceed: false, emergency: true, rwa_number: "RWWAAA #",
        building_number: Ncr::BUILDING_NUMBERS[0], code: "Some WO#",
        office: Ncr::OFFICES[0], description: "Ddddd")
      expect(wo.fields_for_display.sort).to eq([
        ["Amount", 1000],
        ["Building number", Ncr::BUILDING_NUMBERS[0]],
        ["Description", "Ddddd"],
        # No Emergency
        ["Expense type", "BA80"],
        ["Not to exceed", false],
        ["Office", Ncr::OFFICES[0]],
        ["RWA Number", "RWWAAA #"],
        ["Vendor", "Some Vend"],
        ["Work Order / Maximo Ticket Number", "Some WO#"]
      ])
    end
  end

  describe '#add_approvals' do
    let (:cart) { FactoryGirl.create(:cart) }
    it "creates approvers when not an emergency" do
      form = FactoryGirl.create(:ncr_work_order, expense_type: 'BA61')
      cart.proposal.client_data = form
      cart.proposal.save
      form.add_approvals('bob@example.com')
      expect(cart.observations.length).to eq(0)
      expect(cart.approvals.length).to eq(3)
      cart.reload
      expect(cart.approved?).to eq(false)
    end
    it "creates observers when in an emergency" do
      form = FactoryGirl.create(:ncr_work_order, expense_type: 'BA61',
                               emergency: true)
      cart.proposal.client_data = form
      cart.proposal.save
      form.add_approvals('bob@example.com')
      expect(cart.observations.length).to eq(3)
      expect(cart.approvals.length).to eq(0)
      cart.clear_association_cache
      expect(cart.approved?).to eq(true)
    end
  end
  describe '#init_and_save_cart' do
    let(:requester) { FactoryGirl.create(:user) }
    def approver_emails(cart)
      cart.approvals.map {|a| a.user.email_address }
    end

    it "adds the budget approver for a BA80 request" do
      form = FactoryGirl.create(:ncr_work_order, expense_type: 'BA80')
      cart = form.init_and_save_cart('aaa@example.com', requester)

      expect(cart.requester).to eq(requester)
      expect(approver_emails(cart)).to eq(%w(
        aaa@example.com
        communicart.budget.approver@gmail.com
      ))
    end

    it "adds the two approvers for a BA61 request" do
      form = FactoryGirl.build(:ncr_work_order, expense_type: 'BA61')
      cart = form.init_and_save_cart('bbb@example.com', requester)

      expect(cart.requester).to eq(requester)
      expect(approver_emails(cart)).to eq(%w(
        bbb@example.com
        communicart.budget.approver@gmail.com
        communicart.ofm.approver@gmail.com
      ))
    end
  end

  describe '#total_price' do
    let (:work_order) { FactoryGirl.create(:ncr_work_order, amount: 45.36)}
    it 'gets price from amount field' do
      expect(work_order.total_price).to eq(45.36)
    end
  end

  describe '#public_identifier' do
    it 'includes the fiscal year' do
      work_order = FactoryGirl.create(:ncr_work_order, :with_proposal,
                                      created_at: Date.new(2007, 1, 15))
      proposal_id = work_order.proposal.id

      expect(work_order.public_identifier).to eq(
        "FY07-#{proposal_id}")

      work_order.update_attribute(:created_at, Date.new(2007, 10, 1))
      expect(work_order.public_identifier).to eq(
        "FY08-#{proposal_id}")
    end
  end

  describe 'rwa validations' do
    let (:work_order) { FactoryGirl.create(:ncr_work_order) }
    it 'works with one letter followed by 7 numbers' do
      work_order.rwa_number = 'A1234567'
      expect(work_order).to be_valid
    end

    it 'must be 8 chars' do
      work_order.rwa_number = 'A123456'
      expect(work_order).not_to be_valid
    end

    it 'must have a letter at the beginning' do
      work_order.rwa_number = '12345678'
      expect(work_order).not_to be_valid
    end

    it 'is not required' do
      work_order.rwa_number = nil
      expect(work_order).to be_valid
      work_order.rwa_number = ''
      expect(work_order).to be_valid
    end
  end
end
