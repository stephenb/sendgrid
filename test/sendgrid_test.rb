require 'test_helper'

class SendgridTest < Test::Unit::TestCase
  def setup    
    @options = {
      :to => ['test@example.com'],
      :from => 'test@example.com',
      :reply_to => 'reply-to@example.com',
      :subject => 'The Subject',
      :html_content => '<html>content</html>',
      :category => 'MyCategory',
      :substitutions => {
        'first_name' => ['Joe'],
        'last_name' => ['Schmoe', 'Cool']
      }
    }
  end
  
  should "require the same number of items in a substitution array as is in the recipient array" do
    assert_raise ArgumentError do
      test_email = SendgridCampaignTestMailer.create_test(@options)
    end
  end
end
