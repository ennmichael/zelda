# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class SimpleMovingTest < Minitest::Test
  def setup
    @link = Zelda::Logic::Link.new
    @grid = Zelda::Logic::Grid.new
    @grid.create @link, 0, 0
  end

  def test_link_moves_within_bounds
    success = @grid.move @link, :right
    new_x, new_y = @grid.position_of @link

    assert success
    assert_equal 1, new_x
    assert_equal 0, new_y
  end

  def test_link_cant_move_outside_bounds
    success = @grid.move @link, :left
    new_x, new_y = @grid.position_of @link

    assert !success
    assert_equal 0, new_x
    assert_equal 0, new_y
  end

  def test_link_multiple_movements
    results = []
    results << @grid.move(@link, :right)
    results << @grid.move(@link, :down)
    results << @grid.move(@link, :left)
    results << @grid.move(@link, :down)
    results << @grid.move(@link, :up)
    new_x, new_y = @grid.position_of @link

    assert results.all? true
    assert_equal 0, new_x
    assert_equal 1, new_y
  end
end
