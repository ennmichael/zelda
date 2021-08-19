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

      def movable_block
        Graphics::Animation.new default: [Graphics::Sprite.new(block_tiles[1], SPRITE_SCALE, SPRITE_SCALE)]
      end

      private

      def block_tiles
        @block_tiles ||= Gosu::Image.load_tiles('media/blocks.bmp', -2, -1)
      end
    end
  end

  # LinkRendering is a rendering of the Link character.
  class LinkRendering
    MOVEMENT_SPEED = 1.5

    attr_reader :direction

    private_constant :MOVEMENT_SPEED

    def initialize(grid, entity)
      Contracts.not_nil grid
      Contracts.not_nil entity
      Contracts.is grid, Logic::Grid
      Contracts.is entity, Logic::Link

      @grid = grid
      @entity = entity
      @animation = Resources.link_animation
      @x, @y = target_position
      self.direction = :right
      @walking = false
    end

    def update(requested_direction)
      Contracts.direction requested_direction

      x, y = target_position
      if @x == x && @y == y
        update_still requested_direction
      else
        update_moving x, y
      end
    end

    def draw
      case direction
      when :up
        @animation.set(@walking ? :walk_up : :idle_up)
      when :down
        @animation.set(@walking ? :walk_down : :idle_down)
      when :left
        @animation.set(@walking ? :walk_left : :idle_left)
      when :right
        @animation.set(@walking ? :walk_right : :idle_right)
      end

      @animation.draw @x, @y
    end

    private

    attr_writer :direction

    def target_position
      x, y = @grid.position_of @entity
      s = Resources::SPRITE_SIZE
      [x * s + s / 2, y * s + s / 2] unless x.nil? || y.nil?
    end

    def update_still(requested_direction)
      @walking = false
      return if requested_direction.nil? || !@grid.move(@entity, requested_direction)

      @walking = true
      self.direction = requested_direction
    end

    def update_moving(target_x, target_y)
      @walking = false if @x == target_x && @y == target_y
      advance_toward target_x, target_y
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

  # A rendering of the immovable blocks.
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

      @grid.create @link, 0, 0
      @grid.create Logic::Block.new, 0, 1
      @grid.create Logic::Block.new, 1, 1

      @link_rendering = LinkRendering.new @grid, @link
      @blocks_rendering = BlocksRendering.new @grid
    end

    def update
      @link_rendering.update requested_direction
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
    end
  end
end

Zelda::Application.new.show
