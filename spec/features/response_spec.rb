require 'spec_helper'

describe ResponsesController do
  before :each do
    @country = create :country
    @user = create :user, country: @country
    4.times { create :order, user: @user }

    @pcmo = create :pcmo, country: @country
    login @pcmo
  end

  it "can bulk process orders", :worker do
    visit new_user_response_path(@user)
    # TODO: these specifications are brittle ...
    choose :orders_4_delivery_method_delivery
    choose :orders_3_delivery_method_denial
    fill_in :response_extra_text, with: "Extra instructions ..."
    click_on "Send Response"

    expect( page.find(".flash").text ).to match /response.*sent.*#{@user.name}/i
    pending "sent an email"
    pending "sent a text (... if ordered through text?)"
  end

  it "can archive responses" do
    response = create :response, user: @user
    @user.orders.each do |o|
      o.update_attributes response: response, delivery_method: DeliveryMethod.to_a.sample
    end

    visit manage_orders_path
    expect( page ).to have_content @user.first_name
    click_on "archive-#{response.id}" # TODO: less brittle selector

    expect( page.find(".flash").text ).to match /response.*archived/i
    expect( page ).not_to have_content @user.first_name
  end
end
