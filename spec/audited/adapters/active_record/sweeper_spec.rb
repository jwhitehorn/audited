require File.expand_path('../active_record_spec_helper', __FILE__)

class AuditsController < ActionController::Base
  def audit
    @company = Models::ActiveRecord::Company.create
    render :nothing => true
  end

  def update_user
    current_user.update_attributes( :password => 'foo')
    render :nothing => true
  end

  private

  attr_accessor :current_user
  attr_accessor :custom_user
end

describe AuditsController, :adapter => :active_record do
  include RSpec::Rails::ControllerExampleGroup

  before(:each) do
    Audited.current_user_method = :current_user
  end

  let( :user ) { create_user }

  describe "POST audit" do

    it "should audit user" do
      controller.send(:current_user=, user)

      expect {
        post :audit
      }.to change( Audited.audit_class, :count )

      assigns(:company).audits.last.user.should == user
    end
    
    it "should not audit nil user" do
      Audited.skip_nil_users = true
      controller.send(:current_user=, nil)

      expect {
        post :audit
      }.to_not change( Audited.audit_class, :count )

      assigns(:company).audits.count.should == 0
      Audited.skip_nil_users = false
    end

    it "should support custom users for sweepers" do
      controller.send(:custom_user=, user)
      Audited.current_user_method = :custom_user

      expect {
        post :audit
      }.to change( Audited.audit_class, :count )

      assigns(:company).audits.last.user.should == user
    end

    it "should record the remote address responsible for the change" do
      request.env['REMOTE_ADDR'] = "1.2.3.4"
      controller.send(:current_user=, user)

      post :audit

      assigns(:company).audits.last.remote_address.should == '1.2.3.4'
    end

  end

  describe "POST update_user" do

    it "should not save blank audits" do
      controller.send(:current_user=, user)

      expect {
        post :update_user
      }.to_not change( Audited.audit_class, :count )
    end

  end
end
