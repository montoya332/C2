describe "Version check" do
  let(:proposal) { FactoryGirl.create(:proposal, :with_approvers, :with_cart) }

  it "occurs if the cart is modified in after seeing the profile page" do
    login_as(proposal.approvals.first.user)
    visit "/proposals/#{proposal.id}"

    sleep 1.second  # wait to get a new update time
    proposal.cart.update_attribute(:name, 'Some other name')

    click_on 'Approve'

    expect(page).to have_content("This request has recently changed.")
    expect(current_path).to eq("/proposals/#{proposal.id}")
  end
end
