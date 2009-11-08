require 'json'

module SendGrid

  VALID_OPTIONS = [
    :opentrack,
    :clicktrack,
    :ganalytics,
    :gravatar,
    :subscriptiontrack,
    :footer,
    :spamcheck
  ]
  
  def self.included(base)
    base.class_eval do
      class << self
        attr_accessor :default_sg_category, :default_sg_options, :default_subscriptiontrack_text,
                      :default_footer_text, :default_spamcheck_score
      end
      attr_accessor :sg_category, :sg_options, :sg_disabled_options, :subscriptiontrack_text, :footer_text, :spamcheck_score
    end
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
    # Should be a hash containing the html/plain text versions: 
    #   {:html => "html version", :plain => "plan text version"}
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
  end

  # Call within mailer method to override the default value.
  def sendgrid_category(category)
    @sg_category = category
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
  
  private

  # Sets the custom X-SMTPAPI header before sending the email
  def perform_delivery_smtp(mail)
    puts sendgrid_json_headers(mail)
    headers['X-SMTPAPI'] = sendgrid_json_headers(mail)
    super
  end

  # Take all of the options and turn it into the json format that SendGrid expects
  def sendgrid_json_headers(mail)
    header_opts = {}

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

    # Set enables
    header_opts[:filters] = {} unless header_opts.has_key?(:filters)
    if (@sg_options && !@sg_options.empty?) || (@sg_disabled_options && !@sg_disabled_options.empty?)
      # merge the options so that the instance-level "overrides"
      merged = self.class.default_sg_options
      merged += @sg_options if @sg_options
      merged.reject! { |option| @sg_disabled_options.include?(option) } if @sg_disabled_options
      header_opts[:filters] = filters_hash_from_options(merged)
    else
      header_opts[:filters] = filters_hash_from_options(self.class.default_sg_options)
    end

    header_opts.to_json
  end
  
  def filters_hash_from_options(opts)
    filters = {}
    opts.each do |opt|
      filters[opt] = {'settings' => {'enable' => 1}}
      case opt.to_sym
        when :subscriptiontrack
          if @subscriptiontrack_text
            filters[:subscriptiontrack]['settings']['text/html'] = @subscriptiontrack_text[:html]
            filters[:subscriptiontrack]['settings']['text/plain'] = @subscriptiontrack_text[:plain]
          elsif self.class.default_subscriptiontrack_text
            filters[:subscriptiontrack]['settings']['text/html'] = self.class.default_subscriptiontrack_text[:html]
            filters[:subscriptiontrack]['settings']['text/plain'] = self.class.default_subscriptiontrack_text[:plain]
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
      end
    end
    return filters
  end
  
end
