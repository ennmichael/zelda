# frozen_string_literal: true

require_relative 'contracts'

module Zelda
  # Core game logic. This is the domain layer, and it does not know about graphics or input handling.
  module Logic
    # Grid of all game objects.
    class Grid
      SIZE = 10

      def initialize
        @grid = Array.new SIZE do
          Array.new SIZE
        end
      end

      # Move the object obj at the given (x, y) position.
      def create(obj, x, y)
        Contracts.not_nil obj
        Contracts.position x, y
        Contracts.includes x, (0..SIZE)
        Contracts.includes y, (0..SIZE)

        @grid[y][x] = obj
      end

      # Move the object obj in the given direction.
      def move(obj, direction)
        Contracts.direction direction
        Contracts.not_nil direction

        x, y = position_of obj

        return false if x.nil? || y.nil?

        dx, dy = delta_for_direction direction
        new_x = x + dx
        new_y = y + dy

        return false unless within_bounds(new_x, new_y)

        other_obj = @grid[new_y][new_x]
        solid = solid?(other_obj)
        can_push = movable?(other_obj) && can_push?(obj)

        if !solid || (can_push && move(other_obj, direction))
          @grid[new_y][new_x] = @grid[y][x]
          @grid[y][x] = nil
          set_pushed obj, can_push
          true
        else
          false
        end
      end

      def position_of(obj)
        Contracts.not_nil obj

        entities.each do |e|
          return e.x, e.y if e.obj == obj
        end

        nil
      end

      def position_of_all(cls)
        Contracts.not_nil cls
        Contracts.is cls, Class

        entities.select { |e| e.obj.is_a? cls }
                .map { |e| [e.x, e.y] }
      end

      private

      def entities
        unflattened = @grid.each_with_index.map do |row, y|
          row.each_with_index.map do |obj, x|
            obj.nil? ? nil : Entity.new(obj, x, y)
          end
        end
        unflattened.flatten.reject(&:nil?)
      end

      def delta_for_direction(direction)
        lookup = {
          up: [0, -1],
          down: [0, 1],
          left: [-1, 0],
          right: [1, 0]
        }
        lookup[direction]
      end

      def within_bounds(x, y)
        (0..SIZE).include?(x) && (0..SIZE).include?(y)
      end

      # TODO: I could unify these and use symbols, but I feel like something similar must already exist

      def solid?(obj)
        obj.respond_to?(:solid?) && obj.solid?
      end

      def movable?(obj)
        obj.respond_to?(:movable?) && obj.movable?
      end

      def can_push?(obj)
        obj.respond_to?(:can_push?) && obj.can_push?
      end

      def set_pushed(obj, pushed)
        obj.pushed = pushed if obj.respond_to? :pushed=
      end

      Entity = Struct.new :obj, :x, :y

      private_constant :Entity
    end

    # The Link character.
    class Link
      attr_accessor :pushed

      def can_push?
        true
      end

      def solid?
        true
      end
    end

    # A block in the terrain.
    class Block
      def solid?
        true
      end
    end

    # A block in the terrain which can be pushed.
    class MovableBlock
      def solid?
        true
      end

      def movable?
        true
      end
    end
  end
end
