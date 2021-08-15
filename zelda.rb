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

    # A Sprite is a single frame within an animation.
    class Sprite
      attr_reader :duration_ms

      def initialize(image, scale_x, scale_y, duration_ms)
        Contracts.not_nil image
        Contracts.not_nil scale_x
        Contracts.not_nil scale_y
        Contracts.not_nil duration_ms
        Contracts.is image, Gosu::Image
        Contracts.is scale_x, Numeric
        Contracts.is scale_y, Numeric
        Contracts.is duration_ms, Numeric

        @image = image
        @scale_x = scale_x
        @scale_y = scale_y
        @duration_ms = duration_ms
      end

      def flipped
        Sprite.new @image, -@scale_x, @scale_y, @duration_ms
      end

      def infinite
        Sprite.new @image, @scale_x, @scale_y, Float::INFINITY
      end

      def draw(x, y)
        @image.draw_rot x, y, 0, 0, 0.5, 0.5, @scale_x * SPRITE_SCALE, @scale_y * SPRITE_SCALE
      end
    end

    # An animation is a set of sprites playing in a loop.
    # Animations have state and can change sprites.
    class Animation
      def initialize(animation_map)
        animation_map.each_pair do |key, value|
          Contracts.not_nil key
          Contracts.not_nil value
          Contracts.is key, Symbol
          Contracts.is value, Array
          value.each do |x|
            Contracts.not_nil x
            Contracts.is x, Sprite
          end
        end

        @animation_map = animation_map
        @active_animation = animation_map.first.first
        @active_frame = 0
        @last_draw = Gosu.milliseconds
        reset_remaining_duration
      end

      def set(animation)
        Contracts.is animation, Symbol
        Contracts.not_nil animation
        Contracts.includes animation, @animation_map.keys

        return if @active_animation == animation

        @active_animation = animation
        @active_frame = 0
        reset_remaining_duration
      end

      def draw(x, y)
        now = Gosu.milliseconds
        delta = now - @last_draw
        @last_draw = now
        @remaining_duration -= delta

        advance_frame if @remaining_duration <= 0

        active_sprite.draw x, y
      end

      private

      def active_sprite
        @animation_map[@active_animation][@active_frame]
      end

      def reset_remaining_duration
        @remaining_duration = active_sprite.duration_ms
      end

      def advance_frame
        @active_frame += 1
        @active_frame %= @animation_map[@active_animation].length
        reset_remaining_duration
      end
    end

    class << self
      def link_animation
        animation_duration = 100
        down, up, left0, left1 = Gosu::Image.load_tiles('media/link_walk.bmp', -4, -1).map do |tile|
          Sprite.new tile, 1, 1, animation_duration
        end

        Animation.new(
          {
            walk_left: [left1, left0],
            walk_right: [left1.flipped, left0.flipped],
            walk_up: [up, up.flipped],
            walk_down: [down, down.flipped],
            idle_left: [left0.infinite],
            idle_right: [left0.flipped.infinite],
            idle_up: [up.flipped.infinite],
            idle_down: [down.flipped.infinite]
          }
        )
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
