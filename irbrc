# Enable autocompletion
require 'irb/completion'

# We always want PP in irb
require 'pp'

# Auto-indent mode
IRB.conf[:AUTO_INDENT] = true

# Save history to ~/.irb-history
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

if defined?(Rails)
  IRB.conf[:PROMPT][:RAILS] = {
    PROMPT_I: "#{Rails.env}> ",
    PROMPT_N: nil,
    PROMPT_S: nil,
    PROMPT_C: nil,
    RETURN: "=> %s\n",
  }
  IRB.conf[:PROMPT_MODE] = :RAILS

  # Some Rails helpers
  if Rails.env.development?
    module ActiveRecordExtensions
      module ClassMethods
        # Retreive a random record of model
        def random
          @_dev_record_count ||= count
          offset(rand(@_dev_record_count)).first
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

    ActiveRecord::Base.include(ActiveRecordExtensions)
  end

end

