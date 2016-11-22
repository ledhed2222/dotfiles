# Enable autocompletion
require 'irb/completion'

# Auto-indent mode
IRB.conf[:AUTO_INDENT] = true

# Save history to ~/.irb-history
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

# Some Rails helpers
if defined?(Rails) && Rails.env.development?

  module ActiveRecordExtensions
    module ClassMethods
      # Retreive a random record of model
      def random
        offset(rand(count)).first
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end

  ActiveRecord::Base.include(ActiveRecordExtensions)

end

