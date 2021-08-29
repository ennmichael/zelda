# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class MovingWithBlocksTest < Minitest::Test
  def setup
    @game = Zelda::Logic::Game.new link_position: [1, 1], block_positions: [[2, 1]]
  end

  def test_link_cant_move_into_block
    @game.request_link_direction :right
    @game.update
    link_x, link_y = @game.link_position
    block_x, block_y = @game.block_positions.first

    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, block_x
    assert_equal 1, block_y
  end

  def test_link_cant_move_through_block
    @game.request_link_direction :right
    @game.update
    @game.request_link_direction :right
    @game.update
    link_x, link_y = @game.link_position
    block_x, block_y = @game.block_positions.first

    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, block_x
    assert_equal 1, block_y
  end
end
