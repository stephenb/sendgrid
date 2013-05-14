require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'action_mailer'
require 'sendgrid'

class SendgridCampaignTestMailer < ActionMailer::Base
  include SendGrid
  
  sendgrid_enable :opentrack, :clicktrack, :subscriptiontrack, :bypass_list_management
    
  REQUIRED_OPTIONS = [:to, :from, :category, :html_content, :subject]
  
  ##
  # options are:
  # :from the from address
  # :to an array of recipients
  # :substitutions a hash of substitutions of the form: 'text to be
  # replaced' => [replacements]. The order and size of the replacement
  # array must match the :to array
  # :category the sendgrid category used for tracking
  # :html_content, :text_content, :subject
  def create_test(options)
    handle_sendgrid_options(options)
    mail(options)
  end
  
  protected
  def handle_sendgrid_options(options)
    REQUIRED_OPTIONS.each do |option|
      raise ArgumentError.new("Required sendgrid option ':#{option}' missing") unless options[option]
    end
    
    sendgrid_recipients(options[:to])
    
    if options[:substitutions]
      options[:substitutions].each do |find, replace|
        sendgrid_substitute(find, replace)
      end
    end
    
    sendgrid_category(options[:category])
  end
end

class SendgridUniqueArgsMailer < ActionMailer::Base
  include SendGrid
  sendgrid_unique_args({ :test_arg => "test value" })
  
  def unique_args_test_email(options)
    sendgrid_unique_args({ :mailer_method_unique_arg => "some value" })
    mail(options)
  end
end