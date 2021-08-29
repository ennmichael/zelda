# frozen_string_literal: true

require_relative 'contracts'
require_relative 'util'

module Zelda
  # Core game logic. This is the domain layer, and it does not know about graphics or input handling.
  module Logic
    # Entity provides useful class methods for working with entities.
    class << self
      def movable?(obj)
        Util.check obj, :movable?
      end

      def pushable?(obj)
        Util.check obj, :pushable?
      end

      def delta_for_direction(direction)
        @lookup ||= {
          up: [0, -1],
          down: [0, 1],
          left: [-1, 0],
          right: [1, 0]
        }
        @lookup[direction]
      end
    end

    # The Game of Zelda.
    class Game
      def link_position
        @grid.position_of @link
      end

      def link_pushed
        @link.pushed
      end

      def block_positions
        @grid.position_of_all Block
      end

      def pushable_block_positions
        @grid.position_of_all PushableBlock
      end

      def pushable_block_positions_hash
        @grid.positions_hash PushableBlock
      end

      def request_link_direction(direction)
        Contracts.not_nil direction
        Contracts.direction direction

        @link_movement_updater.request_direction direction
      end

      # The constructor expects the following hash keys: link_position, zol_position,
      # block_positions, pushable_block_positions. All are optional.
      def initialize(**args)
        @updaters = []
        @grid = Grid.new

        unless args[:link_position].nil?
          x, y = args[:link_position]
          Contracts.position x, y

          @link = Link.new
          @grid.create @link, x, y
          @link_movement_updater = Updaters::LinkMovementUpdater.new(@grid, @link)
          @updaters << @link_movement_updater
        end

        unless args[:zol_position].nil?
          x, y = args[:zol_position]
          Contracts.position x, y

          @zol = Zol.new
          @grid.create @zol, x, y
          @updaters << Updaters::ZolMovementUpdater.new(@grid, @zol)
        end

        create_blocks = lambda do |block_type, positions|
          positions.each do |pos|
            x, y = pos
            Contracts.position x, y

            block = block_type.new
            @grid.create block, x, y
            @blocks << block
          end
        end

        @blocks = []
        create_blocks.call Block, args[:block_positions] unless args[:block_positions].nil?
        create_blocks.call PushableBlock, args[:pushable_block_positions] unless args[:pushable_block_positions].nil?
      end

      def update
        @updaters.each(&:update)
      end
    end

    GRID_SIZE = 10

    # Grid of all game objects.
    class Grid
      def initialize
        @grid = Array.new GRID_SIZE do
          Array.new GRID_SIZE
        end
      end

      # Move the object obj at the given (x, y) position.
      def create(obj, x, y)
        Contracts.not_nil obj
        Contracts.position x, y
        Contracts.includes x, (0..GRID_SIZE)
        Contracts.includes y, (0..GRID_SIZE)

        @grid[y][x] = obj
      end

      # Move the object obj in the given direction.
      def move(obj, direction)
        Contracts.direction direction
        Contracts.not_nil direction

        return false unless Logic.movable? obj

        x, y = position_of obj

        return false if x.nil? || y.nil?

        dx, dy = Logic.delta_for_direction direction
        new_x = x + dx
        new_y = y + dy

        return false unless within_bounds(new_x, new_y) && @grid[new_y][new_x].nil?

        @grid[new_y][new_x] = @grid[y][x]
        @grid[y][x] = nil
        true
      end

      def object_at(x, y)
        Contracts.position x, y

        @grid[y][x]
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

      def within_bounds(x, y)
        (0...GRID_SIZE).include?(x) && (0...GRID_SIZE).include?(y)
      end

      # Returns a hash mapping object id's of the given class to their respective positions.
      def positions_hash(cls)
        entities.select { |e| e.obj.is_a? cls }
                .map { |e| [e.obj.object_id, [e.x, e.y]] }
                .to_h
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

      Entity = Struct.new :obj, :x, :y

      private_constant :Entity
    end

    private_constant :Grid

    # The Link entity. Link is the main character in the game.
    class Link
      attr_accessor :pushed

      def movable?
        true
      end
    end

    private_constant :Link

    # The Zol entity. Zol is the enemy in the game.
    class Zol
      def movable?
        true
      end
    end

    private_constant :Zol

    # A block in the terrain.
    class Block
    end

    private_constant :Block

    # A block in the terrain which can be pushed.
    class PushableBlock
      def movable?
        true
      end

      def pushable?
        true
      end
    end

    private_constant :PushableBlock

    module Updaters
      # Updater for Link's movement.
      class LinkMovementUpdater
        def initialize(grid, link)
          Contracts.not_nil grid
          Contracts.not_nil link
          Contracts.is grid, Grid
          Contracts.is link, Link

          @grid = grid
          @link = link
        end

        def request_direction(direction)
          Contracts.direction direction

          @requested_direction = direction
        end

        def update
          return if @requested_direction.nil?

          x, y = @grid.position_of @link

          dx, dy = Logic.delta_for_direction @requested_direction
          new_x = x + dx
          new_y = y + dy

          other_obj = @grid.object_at new_x, new_y
          can_push = !other_obj.nil? && Logic.pushable?(other_obj)
          @link.pushed = can_push ? @grid.move(other_obj, @requested_direction) : false
          @grid.move @link, @requested_direction

          @requested_direction = nil
        end
      end

      # Updater for Zol's movement.
      class ZolMovementUpdater
        def initialize(grid, zol)
          Contracts.not_nil grid
          Contracts.not_nil zol
          Contracts.is grid, Grid
          Contracts.is link, Zol

          @grid = grid
          @zol = zol
        end

        def update
          # TODO: If the direction is nil, pick one at "random". "Random" means random direction that is free.
          # With each move have a 1/3 or sth chance of changing the direction. Also change direction if you run
          # into solid terrain.
        end
      end
    end

    private_constant :Updaters
  end
end
