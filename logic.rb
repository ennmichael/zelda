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

        return false unless within_bounds(new_x, new_y) && !solid?(@grid[new_y][new_x])

        @grid[new_y][new_x] = @grid[y][x]
        @grid[y][x] = nil

        true
      end

      def position_of(obj)
        @grid.each_with_index do |row, y|
          x = row.find_index obj
          return x, y unless x.nil?
        end

        nil
      end

      private

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

      def solid?(obj)
        obj.respond_to?(:solid?) && obj.solid?
      end
    end

    # The Link character.
    class Link
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
  end
end
