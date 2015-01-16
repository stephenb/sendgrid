require 'json'

module SendGrid

  VALID_OPTIONS = [
    :opentrack,
    :clicktrack,
    :ganalytics,
    :gravatar,
    :subscriptiontrack,
    :footer,
    :spamcheck,
    :bypass_list_management
  ]

  VALID_GANALYTICS_OPTIONS = [
    :utm_source,
    :utm_medium,
    :utm_campaign,
    :utm_term,
    :utm_content
  ]

  def self.included(base)
    base.class_eval do
      class << self
        attr_accessor :default_sg_category, :default_sg_options, :default_subscriptiontrack_text,
                      :default_footer_text, :default_spamcheck_score, :default_sg_unique_args
      end
      attr_accessor :sg_category, :sg_options, :sg_disabled_options, :sg_recipients, :sg_substitutions,
                    :subscriptiontrack_text, :footer_text, :spamcheck_score, :sg_unique_args, :sg_send_at
    end

    # NOTE: This commented-out approach may be a "safer" option for Rails 3, but it
    # would cause the headers to get set during delivery, and not when the message is initialized.
    # If base supports register_interceptor (i.e., Rails 3 ActionMailer), use it...
    # if base.respond_to?(:register_interceptor)
    #   base.register_interceptor(SendgridInterceptor)
    # end

    base.extend(ClassMethods)
  end

  module ClassMethods

    # Sets a default category for all emails.
    # :use_subject_lines has special behavior that uses the subject-line of
    # each outgoing email for the SendGrid category. This special behavior
    # can still be overridden by calling sendgrid_category from within a
    # mailer method.
    def sendgrid_category(category)
      self.default_sg_category = category
    end

    # Enables a default option for all emails.
    # See documentation for details.
    #
    # Supported options:
    # * :opentrack
    # * :clicktrack
    # * :ganalytics
    # * :gravatar
    # * :subscriptiontrack
    # * :footer
    # * :spamcheck
    def sendgrid_enable(*options)
      self.default_sg_options = Array.new unless self.default_sg_options
      options.each { |option| self.default_sg_options << option if VALID_OPTIONS.include?(option) }
    end
    
    # Sets the default text for subscription tracking (must be enabled).
    # There are two options:
    # 1. Add an unsubscribe link at the bottom of the email
    #   {:html => "Unsubscribe <% here %>", :plain => "Unsubscribe here: <% %>"}
    # 2. Replace given text with the unsubscribe link
    #   {:replace => "<unsubscribe_link>" }
    def sendgrid_subscriptiontrack_text(texts)
      self.default_subscriptiontrack_text = texts
    end

    # Sets the default footer text (must be enabled).
    # Should be a hash containing the html/plain text versions:
    #   {:html => "html version", :plain => "plan text version"}
    def sendgrid_footer_text(texts)
      self.default_footer_text = texts
    end

    # Sets the default spamcheck score text (must be enabled).
    def sendgrid_spamcheck_maxscore(score)
      self.default_spamcheck_score = score
    end

    # Sets unique args at the class level. Should be a hash
    # of name, value pairs.
    #   { :some_unique_arg => "some_value"}
    def sendgrid_unique_args(unique_args = {})
      self.default_sg_unique_args = unique_args
    end
  end

  # Call within mailer method to override the default value.
  def sendgrid_category(category)
    @sg_category = category
  end

  # Call within mailer method to set send time for this mail
  def sendgrid_send_at(utc_timestamp)
    @sg_send_at = utc_timestamp
  end

  # Call within mailer method to set unique args for this email.
  # Merged with class-level unique args, if any exist.
  def sendgrid_unique_args(unique_args = {})
    @sg_unique_args = unique_args
  end

  # Call within mailer method to add an option not in the defaults.
  def sendgrid_enable(*options)
    @sg_options = Array.new unless @sg_options
    options.each { |option| @sg_options << option if VALID_OPTIONS.include?(option) }
  end

  # Call within mailer method to remove one of the defaults.
  def sendgrid_disable(*options)
    @sg_disabled_options = Array.new unless @sg_disabled_options
    options.each { |option| @sg_disabled_options << option if VALID_OPTIONS.include?(option) }
  end

  # Call within mailer method to add an array of recipients
  def sendgrid_recipients(emails)
    @sg_recipients = Array.new unless @sg_recipients
    @sg_recipients = emails
  end

  # Call within mailer method to add an array of substitions
  # NOTE: you must ensure that the length of the substitions equals the
  #       length of the sendgrid_recipients.
  def sendgrid_substitute(placeholder, subs)
    @sg_substitutions = Hash.new unless @sg_substitutions
    @sg_substitutions[placeholder] = subs
  end

  # Call within mailer method to override the default value.
  def sendgrid_subscriptiontrack_text(texts)
    @subscriptiontrack_text = texts
  end

  # Call within mailer method to override the default value.
  def sendgrid_footer_text(texts)
    @footer_text = texts
  end

  # Call within mailer method to override the default value.
  def sendgrid_spamcheck_maxscore(score)
    @spamcheck_score = score
  end

  # Call within mailer method to set custom google analytics options
  # http://sendgrid.com/documentation/appsGoogleAnalytics
  def sendgrid_ganalytics_options(options)
    @ganalytics_options = []
    options.each { |option| @ganalytics_options << option if VALID_GANALYTICS_OPTIONS.include?(option[0].to_sym) }
  end
  
  # only override the appropriate methods for the current ActionMailer version
  if ActionMailer::Base.respond_to?(:mail)

    protected

    # Sets the custom X-SMTPAPI header after creating the email but before delivery
    # NOTE: This override is used for Rails 3 ActionMailer classes.
    def mail(headers={}, &block)
      m = super
      if @sg_substitutions && !@sg_substitutions.empty?
        @sg_substitutions.each do |find, replace|
          raise ArgumentError.new("Array for #{find} is not the same size as the recipient array") if replace.size != @sg_recipients.size
        end
      end
      puts "SendGrid X-SMTPAPI: #{sendgrid_json_headers(message)}" if Object.const_defined?("SENDGRID_DEBUG_OUTPUT") && SENDGRID_DEBUG_OUTPUT
      self.headers['X-SMTPAPI'] = sendgrid_json_headers(message)
      m
    end

  else

    # Sets the custom X-SMTPAPI header after creating the email but before delivery
    # NOTE: This override is used for Rails 2 ActionMailer classes.
    def create!(method_name, *parameters)
      super
      if @sg_substitutions && !@sg_substitutions.empty?
        @sg_substitutions.each do |find, replace|
          raise ArgumentError.new("Array for #{find} is not the same size as the recipient array") if replace.size != @sg_recipients.size
        end
      end
      puts "SendGrid X-SMTPAPI: #{sendgrid_json_headers(mail)}" if Object.const_defined?("SENDGRID_DEBUG_OUTPUT") && SENDGRID_DEBUG_OUTPUT
      @mail['X-SMTPAPI'] = sendgrid_json_headers(mail)
    end

  end

  private

  # Take all of the options and turn it into the json format that SendGrid expects
  def sendgrid_json_headers(mail)
    header_opts = {}

    #if not called within the mailer method, this will be nil so we default to empty hash
    @sg_unique_args = @sg_unique_args || {}
    
    # set the unique arguments
    if @sg_unique_args || self.class.default_sg_unique_args
      unique_args = self.class.default_sg_unique_args || {}
      unique_args = unique_args.merge(@sg_unique_args)

      header_opts[:unique_args] = unique_args unless unique_args.empty?
    end

    # Set category
    if @sg_category && @sg_category == :use_subject_lines
      header_opts[:category] = mail.subject
    elsif @sg_category
      header_opts[:category] = @sg_category
    elsif self.class.default_sg_category && self.class.default_sg_category.to_sym == :use_subject_lines
      header_opts[:category] = mail.subject
    elsif self.class.default_sg_category
      header_opts[:category] = self.class.default_sg_category
    end

    #Set send_at if set by the user
    header_opts[:send_at] = @sg_send_at unless @sg_send_at.blank?

    # Set multi-recipients
    if @sg_recipients && !@sg_recipients.empty?
      header_opts[:to] = @sg_recipients
    end

    # Set custom substitions
    if @sg_substitutions && !@sg_substitutions.empty?
      header_opts[:sub] = @sg_substitutions
    end

    # Set enables/disables
    enabled_opts = []
    if @sg_options && !@sg_options.empty?
      # merge the options so that the instance-level "overrides"
      merged = self.class.default_sg_options || []
      merged += @sg_options
      enabled_opts = merged
    elsif self.class.default_sg_options
      enabled_opts = self.class.default_sg_options
    end
    if !enabled_opts.empty? || (@sg_disabled_options && !@sg_disabled_options.empty?)
      filters = filters_hash_from_options(enabled_opts, @sg_disabled_options)
      header_opts[:filters] = filters if filters && !filters.empty?
    end

    header_opts.to_json.gsub(/(["\]}])([,:])(["\[{])/, '\\1\\2 \\3')
  end

  def filters_hash_from_options(enabled_opts, disabled_opts)
    filters = {}
    enabled_opts.each do |opt|
      filters[opt] = {'settings' => {'enable' => 1}}
      case opt.to_sym
        when :subscriptiontrack
          if @subscriptiontrack_text
            if @subscriptiontrack_text[:replace]
              filters[:subscriptiontrack]['settings']['replace'] = @subscriptiontrack_text[:replace]
            else
              filters[:subscriptiontrack]['settings']['text/html'] = @subscriptiontrack_text[:html]
              filters[:subscriptiontrack]['settings']['text/plain'] = @subscriptiontrack_text[:plain]
            end
          elsif self.class.default_subscriptiontrack_text
            if self.class.default_subscriptiontrack_text[:replace]
              filters[:subscriptiontrack]['settings']['replace'] = self.class.default_subscriptiontrack_text[:replace]
            else
              filters[:subscriptiontrack]['settings']['text/html'] = self.class.default_subscriptiontrack_text[:html]
              filters[:subscriptiontrack]['settings']['text/plain'] = self.class.default_subscriptiontrack_text[:plain]
            end
          end

        when :footer
          if @footer_text
            filters[:footer]['settings']['text/html'] = @footer_text[:html]
            filters[:footer]['settings']['text/plain'] = @footer_text[:plain]
          elsif self.class.default_footer_text
            filters[:footer]['settings']['text/html'] = self.class.default_footer_text[:html]
            filters[:footer]['settings']['text/plain'] = self.class.default_footer_text[:plain]
          end

        when :spamcheck
          if self.class.default_spamcheck_score || @spamcheck_score
            filters[:spamcheck]['settings']['maxscore'] = @spamcheck_score || self.class.default_spamcheck_score
          end

        when :ganalytics
          if @ganalytics_options
            @ganalytics_options.each do |key, value|
              filters[:ganalytics]['settings'][key.to_s] = value
            end
          end
      end
    end

    if disabled_opts
      disabled_opts.each do |opt|
        filters[opt] = {'settings' => {'enable' => 0}}
      end
    end

    return filters
  end

end
