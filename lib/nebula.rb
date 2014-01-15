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

  extend self
end
