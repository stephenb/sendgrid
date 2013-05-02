sendgrid
=========

_Now updated to work with Rails 3._

What is SendGrid?
-----------------

SendGrid is an awesome service that helps you send large amounts of email (bells and whistles included) without spending large amounts of money. This gem allows for painless integration between ActionMailer and the SendGrid SMTP API. The current scope of this gem is focused around setting configuration options for outgoing email (essentially, setting categories, filters and the settings that can accompany those filters). SendGrid's service allows for some other cool stuff (such as postback notification of unsubscribes, bounces, etc.), but those features are currently outside the scope of this gem.

Visit [SendGrid](http://sendgrid.com) to learn more.

Getting Started
---------------

First of all, you'll need the gem. It's at http://rubygems.org/gems/sendgrid. If you're using Bundler, just add the following to your Gemfile.

    gem 'sendgrid'


Before you can do anything with the sendgrid gem, you'll need to create your very own SendGrid account. Go ahead and do so at [http://sendgrid.com](http://sendgrid.com) (there's even a FREE account option).

Next, update your application's SMTP settings to use SendGrid's servers (see [SendGrid's getting started guide](http://wiki.sendgrid.com/doku.php?id=get_started) for instructions).

Example:

    ActionMailer::Base.smtp_settings = {
      :address => "smtp.sendgrid.net",
      :port => 25,
      :domain => "mysite.com",
      :authentication => :plain,
      :user_name => "sendgrd_username",
      :password => "sendgrid_password"
    }

Using the sendgrid Gem
----------------------

If you do not already have an ActionMailer class up and running, then check out [this guide.](http://guides.rubyonrails.org/action_mailer_basics.html#walkthrough-to-generating-a-mailer)

1) add the following line within your mailer class:

    include SendGrid


2) customize your sendgrid settings:

There are 2 main types of settings

* Category settings
* Enable/disable settings

You can set both global and per-email settings - the same syntax is used in either case.
Here is an example of what typical usage may look like:

    class MyMailer < ActionMailer::Base
      include SendGrid
      sendgrid_category :use_subject_lines
      sendgrid_enable   :ganalytics, :opentrack
      sendgrid_unique_args :key1 => "value1", :key2 => "value2"

      def welcome_message(user)
        sendgrid_category "Welcome"
        sendgrid_unique_args :key2 => "newvalue2", :key3 => "value3"
        mail :to => user.email, :subject => "Welcome #{user.name} :-)"
      end

      def goodbye_message(user)
        sendgrid_disable :ganalytics
        mail :to => user.email, :subject => "Fare thee well :-("
      end
    end

Category settings can be any text you like and SendGrid's website will allow you to view email statistics per-category (very nice). There is also a custom global setting that will automatically use the subject line of each email as the sendgrid\_category:

    sendgrid_category :use_subject_lines

If you have any dynamic subject lines, you'll want to override this setting within the mailer method. Calling sendgrid\_category from within one of your mailer methods will override this global setting. Similarly, calling sendgrid\_enable/sendgrid\_disable from within a mailer method will add or remove from any defaults that may have been set globally.

Here are a list of supported options for sendgrid\_enable and sendgrid\_disable:

* :opentrack
* :clicktrack
* :ganalytics
  * Call sendgrid\_ganalytics\_options(:utm_source => 'welcome_email', :utm_medium => 'email', :utm_campaign => 'promo', :utm_term => 'intro+text', :utm_content => 'header_link') to set custom Google Analytics variables.
* :gravatar
* :subscriptiontrack
  * Call sendgrid\_subscriptiontrack\_text(:html => 'Unsubscribe <% Here %>', :plain => 'Unsubscribe Here: <% %>') to set a custom format for html/plain or both.
  * OR Call sendgrid\_subscriptiontrack\_text(:replace => '|unsubscribe\_link|') to replace all occurrences of |unsubscribe\_link| with the url of the unsubscribe link
* :footer
  * Call sendgrid\_footer\_text(:html => 'My HTML footer rocks!', :plain => 'My plain text footer is so-so.') to set custom footer text for html, plain or both.
* :spamcheck
  * Call sendgrid\_spamcheck\_maxscore(4.5) to set a custom SpamAssassin threshold at which SendGrid drops emails (default value is 5.0).

For further explanation see [SendGrid's wiki page on filters.](http://wiki.sendgrid.com/doku.php?id=filters)

Custom parameters can be set using the sendgrid_unique_args methods.  Any key/value pairs defined thusly will
be included as parameters in SendGrid post backs.  These are especially useful in cases where the recipient's
email address is not unique or when multiple applications/environments are using the same SendGrid account.


Delivering to multiple recipients
---------------------------------

There is a per-mailer-method setting that can be used to deliver campaigns to multiple (many) recipients in a single delivery/SMTP call.
It is quite easy to build a robust mass-delivery system utilizing this feature, and it is quite difficult to deliver a large email campaign quickly without this feature.
Note: While it may be worth asking yourself, a SendGrid engineer told me it's best to keep the number of recipients to <= 1,000 per delivery.


    sendgrid_recipients ["email1@blah.com", "email2@blah.com", "email3@blah.com", ...]


One issue that arises when delivering multiple emails at once is custom content. Luckily, there is also a per-mailer-method setting that can be used to substitute custom content.


    sendgrid_substitute "|subme|", ["sub text for 1st recipient", "sub text for 2nd recipient", "sub text for 3rd recipient", ...]


In this example, if <code>|subme|</code> is in the body of your email SendGrid will automatically substitute it for the string corresponding the recipient being delivered to. NOTE: You should ensure that the length of the substitution array is equal to the length of the recipients array.


TODO
----

* Test coverage (I would appreciate help writing tests).
* Possibly integrate with SendGrid's Event API and some of the other goodies they provide.

