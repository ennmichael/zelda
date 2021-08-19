# frozen_string_literal: true

module Zelda
  # Graphics functions.
  module Graphics
    # A Sprite is a single frame within an animation.
    class Sprite
      attr_reader :duration_ms

      def initialize(image, scale_x, scale_y, duration_ms = Float::INFINITY)
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
        @image.draw_rot x, y, 0, 0, 0.5, 0.5, @scale_x, @scale_y
      end
    end

    # An animation is a set of sprites playing in a loop.
    # Animations have state and can change sprites.
    class Animation
      def initialize(**animation_map)
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
  end
end
