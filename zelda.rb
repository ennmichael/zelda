# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'gosu'
require_relative 'logic'

# Top level module.
module Zelda
  # Game resources. Currently only holds sprites.
  module Resources
    SPRITE_SCALE = 3
    SPRITE_SIZE = 16 * SPRITE_SCALE

    private_constant :SPRITE_SCALE

    # Link's sprites.
    class LinkSprites
      WALK_ANIMATION_SPEED = 0.005
      WALK_TILES = 4

      private_constant :WALK_ANIMATION_SPEED, :WALK_TILES

      def initialize
        @walk = Gosu::Image.load_tiles 'media/link_walk.bmp', -WALK_TILES, -1
        @last_sprite = @walk.first
        @last_scale = SPRITE_SCALE
      end

      def draw_facing_up(x, y)
        Contracts.position x, y

        @last_sprite = sprite_walk_up
        @last_scale = ((Gosu.milliseconds * WALK_ANIMATION_SPEED).round % 2).zero? ? SPRITE_SCALE : -SPRITE_SCALE
        draw_last x, y
      end

      def draw_facing_down(x, y)
        Contracts.position x, y

        @last_sprite = sprite_walk_down
        @last_scale = ((Gosu.milliseconds * WALK_ANIMATION_SPEED).round % 2).zero? ? SPRITE_SCALE : -SPRITE_SCALE
        draw_last x, y
      end

      def draw_facing_left(x, y)
        Contracts.position x, y

        @last_sprite = sprites_walk_left[Gosu.milliseconds * WALK_ANIMATION_SPEED % 2]
        @last_scale = SPRITE_SCALE
        draw_last x, y
      end

      def draw_facing_right(x, y)
        Contracts.position x, y

        @last_sprite = sprites_walk_left[Gosu.milliseconds * WALK_ANIMATION_SPEED % 2]
        @last_scale = -SPRITE_SCALE
        draw_last x, y
      end

      def draw_last(x, y)
        @last_sprite.draw_rot x, y, 0, 0, 0.5, 0.5, @last_scale, SPRITE_SCALE
      end

      private

      def sprite_walk_down
        @walk[0]
      end

      def sprite_walk_up
        @walk[1]
      end

      def sprites_walk_left
        @walk[2, 3]
      end
    end

    class BlockSprites
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
      @sprites = Resources::LinkSprites.new
      @x, @y = target_position
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
        @sprites.draw_facing_up @x, @y
      when :down
        @sprites.draw_facing_down @x, @y
      when :left
        @sprites.draw_facing_left @x, @y
      when :right
        @sprites.draw_facing_right @x, @y
      else
        @sprites.draw_last @x, @y
      end
    end

    private

    # TODO: I don't need this. Direction can be determined entirely by looking at current vs target position
    attr_writer :direction

    def target_position
      x, y = @grid.position_of @entity
      s = Resources::SPRITE_SIZE
      [x * s + s / 2, y * s + s / 2] unless x.nil? || y.nil?
    end

    def update_still(requested_direction)
      return if requested_direction.nil? || !@grid.move(@entity, requested_direction)

      self.direction = requested_direction
    end

    def update_moving(target_x, target_y)
      advance_toward target_x, target_y
      self.direction = nil if @x == target_x && @y == target_y
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

  # The game window.
  class Application < Gosu::Window
    def initialize
      super 600, 600
      self.caption = 'Zelda'

      @grid = Logic::Grid.new
      @link = Logic::Link.new
      @grid.create @link, 0, 0
      @link_rendering = LinkRendering.new @grid, @link
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
    end
  end
end

Zelda::Application.new.show
