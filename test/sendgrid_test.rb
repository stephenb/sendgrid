require 'test_helper'

class SendgridTest < Test::Unit::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @options = {
      :to => ['test@example.com'],
      :from => 'test@example.com',
      :reply_to => 'reply-to@example.com',
      :subject => 'The Subject',
      :body => '<html>content</html>',
      :category => 'MyCategory',
      :substitutions => {
        'first_name' => ['Joe'],
        'last_name' => ['Schmoe', 'Cool']
      }
    }
  end

  should "require the same number of items in a substitution array as is in the recipient array" do
    assert_raise ArgumentError do
      test_email = SendgridCampaignTestMailer.create_test(@options).deliver
    end
  end

  should "accept a hash of unique args at the class level" do
    assert_equal ({ :test_arg => "test value" }), SendgridUniqueArgsMailer.default_sg_unique_args
  end

  should "pass unique args from both the mailer class and the mailer method through custom headers" do
    @options.delete(:substitutions)
    SendgridUniqueArgsMailer.unique_args_test_email(@options).deliver
    mail = ActionMailer::Base.deliveries.last
    # assert({ :unique_args => {:mailer_method_unique_arg => "some value", :test_arg => "test value"} }.to_json == mail.header['X-SMTPAPI'].value)
    expected = { 'unique_args' => {'mailer_method_unique_arg' => "some value", 'test_arg' => "test value"} }
    actual = JSON.parse(mail.header['X-SMTPAPI'].value)
    assert_equal(expected, actual)
  end
end
