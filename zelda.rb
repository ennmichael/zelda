# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'gosu'
require_relative 'logic'

# Top level module.
module Zelda
  # Game resources. Currently only holds sprites.
  module Resources
    # Link's sprites.
    class LinkSprites
      WALK_ANIMATION_SPEED = 0.005
      WALK_TILES = 4
      SCALE = 3

      private_constant :WALK_ANIMATION_SPEED, :SCALE

      def initialize
        @walk = Gosu::Image.load_tiles 'media/link_walk.bmp', -WALK_TILES, -1
      end

      def sprite_width
        @walk.first.width * SCALE
      end

      def sprite_height
        @walk.first.height * SCALE
      end

      def draw_walking_up(x, y)
        Contracts.position x, y

        scale_x = ((Gosu.milliseconds * WALK_ANIMATION_SPEED).round % 2).zero? ? SCALE : -SCALE
        sprite_walk_up.draw_rot x, y, 0, 0, 0.5, 0.5, scale_x, SCALE
      end

      def draw_walking_down(x, y)
        Contracts.position x, y

        scale_x = ((Gosu.milliseconds * WALK_ANIMATION_SPEED).round % 2).zero? ? SCALE : -SCALE
        sprite_walk_down.draw_rot x, y, 0, 0, 0.5, 0.5, scale_x, SCALE
      end

      def draw_walking_left(x, y)
        Contracts.position x, y

        sprite = sprites_walk_left[Gosu.milliseconds * WALK_ANIMATION_SPEED % 2]
        sprite.draw_rot x, y, 0, 0, 0.5, 0.5, SCALE, SCALE
      end

      def draw_walking_right(x, y)
        Contracts.position x, y

        sprite = sprites_walk_left[Gosu.milliseconds * WALK_ANIMATION_SPEED % 2]
        sprite.draw_rot x, y, 0, 0, 0.5, 0.5, -SCALE, SCALE
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

  # TODO: I need a change in naming, both are called link and that's odd

  # Link is the main character.
  class LinkRendering
    attr_reader :direction

    def initialize(grid, entity)
      Contracts.not_nil grid
      Contracts.not_nil entity
      Contracts.is grid, Logic::Grid
      Contracts.is entity, Logic::Link

      @grid = grid
      @entity = entity
      @sprites = Resources::LinkSprites.new
      @x, @y = expected_position
    end

    def update(requested_direction)
      Contracts.direction requested_direction

      x, y = expected_position
      if @x == x && @y == y
        update_still requested_direction
      else
        update_moving x, y, requested_direction
      end
    end

    def draw
      case direction
      when :up
        @sprites.draw_walking_up @x, @y
      when :down
        @sprites.draw_walking_down @x, @y
      when :left
        @sprites.draw_walking_left @x, @y
      when :right
        @sprites.draw_walking_right @x, @y
      end
    end

    private

    attr_writer :direction

    def expected_position
      x, y = @grid.position_of @entity
      [x * @sprites.sprite_width, y * @sprites.sprite_height] unless x.nil? || y.nil?
    end

    def update_still(requested_direction)
      return if requested_direction.nil? || !@grid.move(@entity, requested_direction)

      self.direction = requested_direction
    end

    def update_moving(requested_direction, target_x, target_y)
      # TODO: Move from the current to target position, not going too far, taking direction into account
    end
  end

  # The game window.
  class Application < Gosu::Window
    def initialize
      super 600, 600
      self.caption = 'Zelda'

      @grid = Logic::Grid.new
      @link = Logic::Link.new
      @grid.create @link, 1, 1
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
