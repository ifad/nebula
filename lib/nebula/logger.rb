require 'logger'

module Nebula
  class Logger < ::Logger
    def initialize(class_name)
      super(File.open(Nebula.log_path, "w+"))
    end

    def with_logging(level, msg, &block)
      block.call.tap { send(level, msg) }
    end
  end
end
