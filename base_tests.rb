require 'minitest/autorun'
require_relative 'main'

class DivCenteringGameTest < Minitest::Test
  def setup
    @game = DivCenteringGame.new
  end

  def teardown
    @game.close
  end

  def test_initial_state
    assert_equal :home, @game.instance_variable_get(:@state)
    assert_equal 0, @game.instance_variable_get(:@score)
    assert_equal false, @game.instance_variable_get(:@game_over)
    assert_empty @game.instance_variable_get(:@divs)
  end

  def test_speed_increment
    game = @game
    initial_speed = game.instance_variable_get(:@current_div_speed)
    
    # Simulate scoring 10 points
    10.times do
      game.instance_variable_set(:@score, game.instance_variable_get(:@score) + 1)
      game.check_and_scroll
    end
    
    new_speed = game.instance_variable_get(:@current_div_speed)
    assert_operator new_speed, :>, initial_speed
  end

  def test_game_over_state
    game = @game
    game.instance_variable_set(:@current_div, { width: 40 })  # Set width below min
    game.place_div
    assert game.instance_variable_get(:@game_over)
  end

  def test_reset_functionality
    game = @game
    game.instance_variable_set(:@score, 10)
    game.instance_variable_set(:@game_over, true)
    game.reset_game
    
    assert_equal 0, game.instance_variable_get(:@score)
    assert_equal false, game.instance_variable_get(:@game_over)
    assert_empty game.instance_variable_get(:@divs)
  end

  def test_credits_screen
    assert_equal 2, @game.instance_variable_get(:@credits_options).length
    assert @game.instance_variable_get(:@credits_options).all? { |c| c[:url].start_with?('https://github.com/') }
  end

  def test_alignment_positions
    alignments = @game.instance_variable_get(:@alignment_options)
    assert_equal 7, alignments.length
    assert_includes alignments, :center
  end
end
