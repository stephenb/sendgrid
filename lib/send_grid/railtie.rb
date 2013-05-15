require 'rails'

module SendGrid
  class Railtie < Rails::Railtie # :nodoc:

    initializer "send_grid.action_mailer" do
      ActiveSupport.on_load(:action_mailer) { ActionMailer::Base.send(:include, SendGrid) }
    end

  end
end
