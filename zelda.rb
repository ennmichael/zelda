# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'gosu'
require_relative 'logic'
require_relative 'graphics'

# Top level module.
module Zelda
  # Game resources. Currently only holds sprites.
  module Resources
    SPRITE_SCALE = 3
    SPRITE_SIZE = 16 * SPRITE_SCALE

    private_constant :SPRITE_SCALE

    class << self
      def link_animation
        tiles = Gosu::Image.load_tiles('media/link_walk.bmp', -4, -1)

        down, up = tiles[0..1].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 130
        end
        left0, left1 = tiles[2..3].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 100
        end

        Graphics::Animation.new walk_left: [left1, left0],
                                walk_right: [left1.flipped, left0.flipped],
                                walk_up: [up, up.flipped],
                                walk_down: [down, down.flipped],
                                idle_left: [left0.infinite],
                                idle_right: [left0.flipped.infinite],
                                idle_up: [up.flipped.infinite],
                                idle_down: [down.flipped.infinite]
      end

      def block_animation
        Graphics::Animation.new default: [Graphics::Sprite.new(block_tiles.first, SPRITE_SCALE, SPRITE_SCALE)]
      end

      def movable_block_animation
        Graphics::Animation.new default: [Graphics::Sprite.new(block_tiles[1], SPRITE_SCALE, SPRITE_SCALE)]
      end

      private

      def block_tiles
        @block_tiles ||= Gosu::Image.load_tiles('media/blocks.bmp', -2, -1)
      end
    end
  end

  # A mixin for rendeing movements with a special animation.
  class MovementRendering
    MOVEMENT_SPEED = 1.5

    private_constant :MOVEMENT_SPEED

    def initialize(grid, entity, animation)
      Contracts.not_nil grid
      Contracts.not_nil entity
      Contracts.not_nil animation
      Contracts.is grid, Logic::Grid
      Contracts.is animation, Graphics::Animation

      @grid = grid
      @entity = entity
      @animation = animation
      @x, @y = target_position
    end

    def update
      x, y = target_position
      advance_toward x, y if moving
    end

    def draw
      @animation.draw @x, @y
    end

    private

    def moving
      x, y = target_position
      @x != x || @y != y
    end

    def direction
      x, y = target_position

      if @x < x
        :right
      elsif x < @x
        :left
      elsif @y < y
        :down
      elsif y < @y
        :up
      end
    end

    def target_position
      x, y = @grid.position_of @entity
      s = Resources::SPRITE_SIZE

      if x.nil? || y.nil?
        [nil, nil]
      else
        [x * s + s / 2, y * s + s / 2]
      end
    end

    def advance_toward(target_x, target_y)
      case direction
      when :up
        @y = [@y - MOVEMENT_SPEED, target_y].max
      when :down
        @y = [@y + MOVEMENT_SPEED, target_y].min
      when :left
        @x = [@x - MOVEMENT_SPEED, target_x].max
      when :right
        @x = [@x + MOVEMENT_SPEED, target_x].min
      end
    end
  end

  # LinkRendering is a rendering of the Link character.
  class LinkRendering < MovementRendering
    def initialize(grid, entity)
      Contracts.not_nil grid
      Contracts.not_nil entity
      Contracts.is grid, Logic::Grid
      Contracts.is entity, Logic::Link

      super grid, entity, Resources.link_animation
      @last_direction = :right
    end

    def update(requested_direction)
      Contracts.direction requested_direction

      request_direction requested_direction
      update_animation
      super()
    end

    private

    def request_direction(requested_direction)
      return if moving || requested_direction.nil? || !@grid.move(@entity, requested_direction)

      @last_direction = direction
    end

    def update_animation
      case @last_direction
      when :up
        @animation.set(moving ? :walk_up : :idle_up)
      when :down
        @animation.set(moving ? :walk_down : :idle_down)
      when :left
        @animation.set(moving ? :walk_left : :idle_left)
      when :right
        @animation.set(moving ? :walk_right : :idle_right)
      end
    end
  end

  # A rendering of all immovable blocks.
  class BlocksRendering
    def initialize(grid)
      Contracts.not_nil grid
      Contracts.is grid, Logic::Grid

      @grid = grid
      @animation = Resources.block_animation
    end

    def draw
      @grid.position_of_all(Logic::Block).each do |x, y|
        draw_single x, y
      end
    end

    private

    def draw_single(x, y)
      s = Resources::SPRITE_SIZE
      x = x * s + s / 2
      y = y * s + s / 2
      @animation.draw x, y
    end
  end

  # The game window.
  class Application < Gosu::Window
    def initialize
      super 600, 600
      self.caption = 'Zelda'

      @grid = Logic::Grid.new
      @link = Logic::Link.new
      @movable_block = Logic::MovableBlock.new

      @grid.create @link, 0, 0
      @grid.create Logic::Block.new, 0, 1
      @grid.create Logic::Block.new, 1, 1
      @grid.create @movable_block, 2, 1

      @link_rendering = LinkRendering.new @grid, @link
      @blocks_rendering = BlocksRendering.new @grid
      @movable_block_rendering = MovementRendering.new @grid, @movable_block, Resources.movable_block_animation
    end

    def update
      @link_rendering.update requested_direction
      @movable_block_rendering.update
    end

    def requested_direction
      if Gosu.button_down? Gosu::KB_D
        :right
      elsif Gosu.button_down? Gosu::KB_A
        :left
      elsif Gosu.button_down? Gosu::KB_W
        :up
      elsif Gosu.button_down? Gosu::KB_S
        :down
      end
    end

    def draw
      @link_rendering.draw
      @blocks_rendering.draw
      @movable_block_rendering.draw
    end
  end
end

Zelda::Application.new.show
