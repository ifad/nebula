require "nebula/version"
require "nebula/db"

module Nebula
  @@config = { }

  def config
    @@config
  end

  def database=(conf)
    config[:database] = conf
  end

  def database
    config[:database]
  end

  def log_path=(path)
    config[:log_path] = path
  end

  def log_path
    config[:log_path] || "/dev/null"
  end

  extend self
end
