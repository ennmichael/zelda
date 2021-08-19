# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class MovingWithBlocksTest < Minitest::Test
  def setup
    @link = Zelda::Logic::Link.new
    @block = Zelda::Logic::Block.new
    @grid = Zelda::Logic::Grid.new
    @grid.create @link, 1, 1
    @grid.create @block, 2, 1
  end

  def test_link_cant_move_into_block
    success = @grid.move @link, :right
    link_x, link_y = @grid.position_of @link
    block_x, block_y = @grid.position_of @block

    assert !success
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, block_x
    assert_equal 1, block_y
  end

  def test_link_cant_move_through_block
    results = []
    results << @grid.move(@link, :right)
    results << @grid.move(@link, :right)
    link_x, link_y = @grid.position_of @link
    block_x, block_y = @grid.position_of @block

    assert results.all? false
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, block_x
    assert_equal 1, block_y
  end
end
