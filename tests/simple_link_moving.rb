# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class SimpleMovingTest < Minitest::Test
  def setup
    @game = Zelda::Logic::Game.new link_position: [0, 0]
  end

  def test_link_moves_within_bounds
    @game.request_link_direction :right
    @game.update
    new_x, new_y = @game.link_position

    assert_equal 1, new_x
    assert_equal 0, new_y
  end

  def test_second_update_does_not_move
    @game.request_link_direction :right
    @game.update
    new_x, new_y = @game.link_position

    assert_equal 1, new_x
    assert_equal 0, new_y

    @game.update
    new_x, new_y = @game.link_position

    assert_equal 1, new_x
    assert_equal 0, new_y
  end

  def test_link_cant_move_outside_bounds
    @game.request_link_direction :left
    @game.update
    new_x, new_y = @game.link_position

    assert_equal 0, new_x
    assert_equal 0, new_y
  end

  def test_link_multiple_movements
    @game.request_link_direction :right
    @game.update
    @game.request_link_direction :down
    @game.update
    @game.request_link_direction :left
    @game.update
    @game.request_link_direction :down
    @game.update
    @game.request_link_direction :up
    @game.update
    new_x, new_y = @game.link_position

    assert_equal 0, new_x
    assert_equal 1, new_y
  end
end
