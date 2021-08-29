# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../logic'

# Tests Zol's moving functionality.
class ZolMovementTests < Minitest::Test
  def test_doesnt_move_out_of_bounds_or_into_walls
    game = Zelda::Logic::Game.new zol_position: [0, 0],
                                  block_positions: [[2, 2], [3, 2], [4, 2], [2, 5], [6, 2], [7, 1]]

    previous_x, previous_y = game.zol_position
    1000.times do
      game.update
      new_x, new_y = game.zol_position

      assert new_x != previous_x || new_y != previous_y
      assert_includes (0...Zelda::Logic::GRID_SIZE), new_x
      assert_includes (0...Zelda::Logic::GRID_SIZE), new_y

      previous_x = new_x
      previous_y = new_y
    end
  end

  def test_follows_only_available_path
    game = Zelda::Logic::Game.new zol_position: [0, 0],
                                  block_positions: [
                                    [0, 1], [1, 1], [2, 1], [3, 1], [4, 1],
                                    [5, 1], [6, 1], [7, 1], [8, 1], [9, 1]
                                  ]

    previous_x, previous_y = game.zol_position
    9.times do
      game.update
      new_x, new_y = game.zol_position

      assert_equal new_x, previous_x + 1
      assert_equal new_y, previous_y

      previous_x = new_x
      previous_y = new_y
    end
  end

  def test_turns_180_only_when_necessary
    game = Zelda::Logic::Game.new zol_position: [0, 0],
                                  block_positions: [[0, 1], [1, 1], [2, 0]]

    game.update
    game.update

    x, y = game.zol_position

    assert_equal 0, x
    assert_equal 0, y
  end
end
