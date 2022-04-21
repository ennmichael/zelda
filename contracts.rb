# frozen_string_literal: true

module Zelda
  # TODO: Perhaps I should split the Logic contracts (position, direction) from the general purpose contracts (is, bool)

  # Formal development contracts.
  class Contracts
    class << self
      def direction(direction)
        raise "#{direction} is not a direction" unless [:up, :down, :left, :right, nil].include? direction
      end

      def not_nil(obj)
        raise 'object is nil' if obj.nil?
      end

      def position(x, y)
        not_nil x
        not_nil y
        is x, Numeric
        is y, Numeric
      end

      def includes(value, range)
        raise "#{value} in not in #{range}" unless value.nil? || range.include?(value)
      end

      def condition(bool, msg)
        raise "Condition failed: #{msg}" unless bool
      end

      def is(obj, type)
        raise "#{obj} is not an instance of #{type}" unless obj.nil? || obj.is_a?(type)
      end

      def bool(obj)
        raise "#{obj} is not a boolean" unless [true, false, nil].include? obj
      end
    end
  end
end
