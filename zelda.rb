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
        walk_tiles = Gosu::Image.load_tiles('media/link_walk.bmp', -6, -1)
        push_tiles = Gosu::Image.load_tiles('media/link_push.bmp', -6, -1)

        walk_down, walk_up = walk_tiles[0..1].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 130
        end
        walk_left0, walk_left1 = walk_tiles[2..3].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 100
        end

        idle_down = Graphics::Sprite.new walk_tiles[4], SPRITE_SCALE, SPRITE_SCALE
        idle_up = Graphics::Sprite.new walk_tiles[5], SPRITE_SCALE, SPRITE_SCALE

        push_down0, push_down1, push_up0, push_up1 = push_tiles[0..3].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 130
        end
        push_left0, push_left1 = push_tiles[4..5].map do |tile|
          Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 100
        end
        push_right0 = push_left0.flipped
        push_right1 = push_left1.flipped

        Graphics::Animation.new walk_left: [walk_left1, walk_left0],
                                walk_right: [walk_left1.flipped, walk_left0.flipped],
                                walk_up: [walk_up, walk_up.flipped],
                                walk_down: [walk_down, walk_down.flipped],
                                idle_left: [walk_left0.infinite],
                                idle_right: [walk_left0.flipped.infinite],
                                idle_up: [idle_up],
                                idle_down: [idle_down],
                                push_left: [push_left0, push_left1],
                                push_right: [push_right0, push_right1],
                                push_up: [push_up0, push_up1],
                                push_down: [push_down0, push_down1]
      end

      def zol_animation
        zol_tiles = Gosu::Image.load_tiles('media/zol.bmp', -2, -1)
        sprites = zol_tiles.map { |tile| Graphics::Sprite.new tile, SPRITE_SCALE, SPRITE_SCALE, 250 }
        Graphics::Animation.new default: sprites
      end

      def block_animation
        Graphics::Animation.new default: [Graphics::Sprite.new(block_tiles[1], SPRITE_SCALE, SPRITE_SCALE)]
      end

      def pushable_block_animation
        Graphics::Animation.new default: [Graphics::Sprite.new(block_tiles.first, SPRITE_SCALE, SPRITE_SCALE)]
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

    def initialize(game, animation)
      Contracts.not_nil game
      Contracts.not_nil animation
      Contracts.is game, Logic::Game
      Contracts.is animation, Graphics::Animation

      @game = game
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
      x, y = entity_position
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
    def initialize(game)
      super game, Resources.link_animation
      @last_direction = :right
    end

    def update(requested_direction)
      Contracts.direction requested_direction

      @last_direction = direction unless direction.nil?
      update_animation
      super()
      @game.request_link_direction requested_direction unless moving || requested_direction.nil?
    end

    private

    def entity_position
      @game.link_position
    end

    def update_animation
      sprite_prefix = if moving
                        @game.link_pushed ? 'push' : 'walk'
                      else
                        'idle'
                      end

      @animation.set("#{sprite_prefix}_#{@last_direction}".to_sym)
    end
  end

  # A rendering of the Zol character.
  class ZolRendering < MovementRendering
    def initialize(game)
      super game, Resources.zol_animation
    end

    def update
      @game.zol_paused = moving
      super()
    end

    private

    def entity_position
      @game.zol_position
    end
  end

  # A rendering of all immovable blocks.
  class BlocksRendering
    def initialize(game)
      Contracts.not_nil game
      Contracts.is game, Logic::Game

      @game = game
      @animation = Resources.block_animation
    end

    def draw
      @game.block_positions.each do |x, y|
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

  # Rendering for a pushable block.
  class PushableBlockRendering < MovementRendering
    def initialize(game, entity_id)
      Contracts.not_nil game
      Contracts.not_nil entity_id
      Contracts.is game, Logic::Game
      Contracts.is entity_id, Integer

      @entity_id = entity_id
      super game, Resources.pushable_block_animation
    end

    private

    def entity_position
      @game.pushable_block_positions_hash[@entity_id]
    end

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
      window_size = Resources::SPRITE_SIZE * Logic::GRID_SIZE
      super window_size, window_size
      self.caption = 'Zelda'

      @game = Logic::Game.new link_position: [0, 0],
                              zol_position: [5, 5],
                              block_positions: [[0, 1], [1, 1]],
                              pushable_block_positions: [[2, 1]]

      @link_rendering = LinkRendering.new @game
      @zol_rendering = ZolRendering.new @game
      @blocks_rendering = BlocksRendering.new @game
      @pushable_block_rendering = PushableBlockRendering.new @game, @game.pushable_block_positions_hash.first.first
    end

    def update
      @game.update
      @link_rendering.update requested_direction
      @zol_rendering.update
      @pushable_block_rendering.update
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
      @zol_rendering.draw
      @blocks_rendering.draw
      @pushable_block_rendering.draw
    end
  end
end

Zelda::Application.new.show
