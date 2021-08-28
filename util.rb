# frozen_string_literal: true

require_relative './contracts'

module Zelda
  # Various Ruby utilities.
  module Util
    class << self
      def check(obj, message)
        Contracts.not_nil message
        Contracts.is message, Symbol

        obj.respond_to?(message) && obj.send(message)
      end
    end
  end
end
