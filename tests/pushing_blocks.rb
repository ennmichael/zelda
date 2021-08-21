# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests simple moving functionality in the presence of only one object on the grid.
class PushingBlocksTest < Minitest::Test
  def setup
    @link = Zelda::Logic::Link.new
    @block = Zelda::Logic::Block.new
    @movable_block = Zelda::Logic::MovableBlock.new
    @grid = Zelda::Logic::Grid.new
  end

  def test_simple_push
    @grid.create @link, 1, 1
    @grid.create @movable_block, 2, 1

    success = @grid.move @link, :right
    link_x, link_y = @grid.position_of @link
    movable_block_x, movable_block_y = @grid.position_of @movable_block

    assert success
    assert @link.pushed
    assert_equal 2, link_x
    assert_equal 1, link_y
    assert_equal 3, movable_block_x
    assert_equal 1, movable_block_y
  end

  def test_cant_push_out_of_bounds
    @grid.create @link, 1, 1
    @grid.create @movable_block, 0, 1

    success = @grid.move @link, :left
    link_x, link_y = @grid.position_of @link
    movable_block_x, movable_block_y = @grid.position_of @movable_block

    assert !success
    assert !@link.pushed
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 0, movable_block_x
    assert_equal 1, movable_block_y
  end

  def test_cant_push_into_solid_block
    @grid.create @link, 1, 1
    @grid.create @movable_block, 2, 1
    @grid.create @block, 3, 1

    success = @grid.move @link, :right
    link_x, link_y = @grid.position_of @link
    movable_block_x, movable_block_y = @grid.position_of @movable_block
    block_x, block_y = @grid.position_of @block

    assert !success
    assert !@link.pushed
    assert_equal 1, link_x
    assert_equal 1, link_y
    assert_equal 2, movable_block_x
    assert_equal 1, movable_block_y
    assert_equal 3, block_x
    assert_equal 1, block_y
  end

  def test_pushed_set_properly
    @grid.create @link, 1, 1
    @grid.create @movable_block, 2, 1

    success = @grid.move @link, :right

    assert success
    assert @link.pushed

    success = @grid.move @link, :down

    assert success
    assert !@link.pushed
  end
end
