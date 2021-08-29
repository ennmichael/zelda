# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class PushingBlocksTest < Minitest::Test
  def test_simple_push
    game = Zelda::Logic::Game.new link_position: [1, 1], pushable_block_positions: [[2, 1]]

    game.request_link_direction :right
    game.update
    link_x, link_y = game.link_position
    pushable_block_x, pushable_block_y = game.pushable_block_positions.first

    assert game.link_pushed
    assert_equal 2, link_x
    assert_equal 1, link_y
    assert_equal 3, pushable_block_x
    assert_equal 1, pushable_block_y
  end

  def test_cant_push_out_of_bounds
    game = Zelda::Logic::Game.new link_position: [1, 1], pushable_block_positions: [[0, 1]]

    game.request_link_direction :left
    game.update
    link_x, link_y = game.link_position
    pushable_block_x, pushable_block_y = game.pushable_block_positions.first

    assert !game.link_pushed
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 0, pushable_block_x
    assert_equal 1, pushable_block_y
  end

  def test_cant_push_into_solid_block
    game = Zelda::Logic::Game.new link_position: [1, 1], block_positions: [[3, 1]], pushable_block_positions: [[2, 1]]

    game.request_link_direction :right
    game.update
    link_x, link_y = game.link_position
    pushable_block_x, pushable_block_y = game.pushable_block_positions.first
    block_x, block_y = game.block_positions.first

    assert !game.link_pushed
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, pushable_block_x
    assert_equal 1, pushable_block_y
    assert_equal 3, block_x
    assert_equal 1, block_y
  end

  def test_pushed_set_properly
    game = Zelda::Logic::Game.new link_position: [1, 1], pushable_block_positions: [[2, 1]]

    game.request_link_direction :right
    game.update

    assert game.link_pushed

    game.request_link_direction :down
    game.update

    assert !game.link_pushed
  end
end
