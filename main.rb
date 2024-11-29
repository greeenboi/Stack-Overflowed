require 'gosu'

class DivCenteringGame < Gosu::Window
  def initialize
    super 1024, 600, false  
    self.caption = "Stack Overflowed"

    # Game state 
    @score = 0
    @game_over = false
    @divs = []

    # Scrolling 
    @scroll_offset = 0

    # Moving div 
    @current_div = nil
    @current_div_x = 0
    @current_div_y = 0
    @current_div_direction = 1
    @current_div_speed = 5
    @descending = false
    @descent_speed = 50  

    # Colors
    @div_colors = [
      Gosu::Color.new(255, 59, 130, 246),  # Blue
      Gosu::Color.new(255, 255, 87, 34),   # Orange
      Gosu::Color.new(255, 76, 175, 80)    # Green
    ]

    # Alignment options
    @alignment_options = [:far_left, :left, :center_left, :center, :center_right, :right, :far_right]

    # Fonts
    @title_font = Gosu::Font.new(self, 'assets/Coconut.ttf', 30)  
    @score_font = Gosu::Font.new(self, Gosu.default_font_name, 24)
    @game_over_font = Gosu::Font.new(self, 'assets/Coconut.ttf', 40)

    # Other
    @background_color = Gosu::Color.new(255, 240, 240, 240) 
    @drop_sound = Gosu::Sample.new('assets/drop.wav')
    @fail_sound = Gosu::Sample.new('assets/fail.wav')
    @fail_sound3 = Gosu::Sample.new('assets/fail3.wav')
    @fail_sound4 = Gosu::Sample.new('assets/fail4.wav')
    @start_sound = Gosu::Sample.new('assets/start.wav')
    @scoreup_sound = Gosu::Sample.new('assets/scoreup.wav')
    @div_height = 50
    @game_width = 800   
    @game_x_start = (width - @game_width) / 2

    # BGM
    @bg_tracks = [
      Gosu::Song.new('assets/bgm1.wav'),
      Gosu::Song.new('assets/bgm2.wav'),
      Gosu::Song.new('assets/bgm3.wav'),
      Gosu::Song.new('assets/bgm4.wav')
    ]
    @current_track = nil
    @bg_volume = 0.3  # Add this line to control background volume

    
    @logo = Gosu::Image.new('assets/images/logo.png')
    @div_texture = Gosu::Image.new('assets/images/div_texture.png')
    @background_texture = Gosu::Image.new('assets/images/background.png')
    @main_menu_texture = Gosu::Image.new('assets/images/main_menu_bg.png')

   
    @initial_width = 500  
    @min_width = 50      
    spawn_moving_div

    @state = :home
    @home_options = ['Play', 'Exit']
    @selected_option = 0

    @initial_speed = 5
    @speed_increment = 1
    @flicker_duration = 0
    @flicker_max_duration = 10  # Number of frames the flicker lasts
  end

  def play_random_bgm
    @current_track&.stop
    @current_track = @bg_tracks.sample
    @current_track.volume = @bg_volume  # Set the volume
    @current_track.play(true) # true means loop
  end

  def stop_bgm
    @current_track&.stop
    @current_track = nil
  end

  def spawn_moving_div
    width = if @divs.empty?
              @initial_width
            else
              [@divs.last[:width] - 10, @min_width].max
            end
    
    @current_div = {
      width: width,
      alignment: @alignment_options.sample,
      color: @div_colors.sample,
      y: 0
    }
    @current_div_x = @game_x_start
    @current_div_y = 50
    @current_div_direction = 1
    @descending = false
  end

  def calculate_overlap(current_x, last_div)
    return nil unless last_div
    
    current_right = current_x + @current_div[:width]
    last_x = last_div[:actual_x] || @game_x_start
    last_right = last_x + last_div[:width]
    
    overlap_left = [current_x, last_x].max
    overlap_right = [current_right, last_right].min
    
    if overlap_right > overlap_left
      {
        width: overlap_right - overlap_left,
        x: overlap_left
      }
    else
      nil
    end
  end

  def button_down(id)
    case @state
    when :home
      case id
      when Gosu::KB_UP
        @selected_option = (@selected_option - 1) % @home_options.length
      when Gosu::KB_DOWN
        @selected_option = (@selected_option + 1) % @home_options.length
      when Gosu::KB_RETURN
        case @selected_option
        when 0
          @start_sound.play  
          @state = :playing
          reset_game
          play_random_bgm
        when 1
          close
        end
      end
    when :playing
      case id
      when Gosu::KB_SPACE
        place_div
      when Gosu::KB_R
        reset_game if @game_over
      when Gosu::KB_ESCAPE
        close
      end
    end
  end

  def play_fail_sound
    sounds = [@fail_sound, @fail_sound3, @fail_sound4]
    sounds.sample.play
  end

  def place_div
    return if @game_over || @current_div.nil? || @descending

    if @divs.empty?
      @descending = true
      @current_div[:actual_x] = @current_div_x
      return
    end

    last_div = @divs.last
    overlap = calculate_overlap(@current_div_x, last_div)
    
    if overlap
      @descending = true
      @current_div[:width] = overlap[:width]
      @current_div[:actual_x] = overlap[:x]
      
      if @current_div[:width] < @min_width
        @game_over = true
        stop_bgm
        play_fail_sound  
      end
    else
      @game_over = true
      stop_bgm
      play_fail_sound  
    end
  end

  def determine_alignment(x)
    section_width = @game_width / 7
    relative_x = x + @current_div[:width] / 2 - @game_x_start
    
    case relative_x
    when 0..section_width
      :far_left
    when section_width..(section_width * 2)
      :left
    when (section_width * 2)..(section_width * 3)
      :center_left
    when (section_width * 3)..(section_width * 4)
      :center
    when (section_width * 4)..(section_width * 5)
      :center_right
    when (section_width * 5)..(section_width * 6)
      :right
    else
      :far_right
    end
  end

  def update
    return if @game_over
    
    # Update flicker
    @flicker_duration -= 1 if @flicker_duration > 0

    if @descending
      # Descend
      @current_div_y += @descent_speed

      # Check if div has reached the bottom of the stack
      if @divs.empty? && @current_div_y >= height - @div_height
        @score += 1
        @drop_sound.play
        @current_div[:y] = 0
        @divs << @current_div
        spawn_moving_div
        check_and_scroll
      elsif !@divs.empty? && @current_div_y >= height - (@divs.length + 1) * @div_height
        @score += 1
        @drop_sound.play
        @current_div[:y] = @divs.length * @div_height
        @divs << @current_div
        spawn_moving_div
        check_and_scroll
      end
    else
      
      @current_div_x += @current_div_direction * @current_div_speed

      
      if @current_div_x <= @game_x_start || 
         @current_div_x + @current_div[:width] >= @game_x_start + @game_width
        @current_div_direction *= -1
      end
    end
  end

  def check_and_scroll
    tower_height = @divs.length * @div_height

    # If tower is more than half the screen height, scroll
    if tower_height > height / 2
      scroll_amount = tower_height - height / 2
      @scroll_offset += scroll_amount
      
      # Remove divs that are off the screen DONT REMOVE THIS!!
      @divs.each { |div| div[:y] -= scroll_amount }
      @divs.reject! { |div| div[:y] < 0 }
    end

    # Check for score milestones
    if @score > 0 && @score % 10 == 0
      @current_div_speed += @speed_increment
      @scoreup_sound.play
      @flicker_duration = @flicker_max_duration  # Trigger flicker effect
    end
  end

  def reset_game
    @score = 0
    @game_over = false
    @divs = []
    @scroll_offset = 0
    @current_div_speed = @initial_speed
    @start_sound.play  
    spawn_moving_div
    @state = :playing
    play_random_bgm
  end

  def draw
    case @state
    when :home
      draw_home_screen
    when :playing
      draw_game_screen
    end
  end

  def draw_home_screen
    @main_menu_texture.draw(
      0, 0, 0,
      width.to_f / @main_menu_texture.width,
      height.to_f / @main_menu_texture.height,
      Gosu::Color::WHITE  # Full opacity
    )
    
    scale = 0.5
    @logo.draw(
      width / 2 - (@logo.width * scale) / 2,
      height / 4 - (@logo.height * scale) / 2,
      1,
      scale,
      scale
    )

    title_text = "Stack Overflowed"
    subtitle_text = "Align Me If You Can"
    
    title_width = @game_over_font.text_width(title_text)
    @game_over_font.draw_text(
      title_text,
      width / 2 - title_width / 2, 
      height / 3,
      1, 1, 1, Gosu::Color::WHITE
    )

    
    subtitle_width = @title_font.text_width(subtitle_text)
    @title_font.draw_text(
      subtitle_text,
      width / 2 - subtitle_width / 2,
      height / 3 + 50,
      1, 1, 1, Gosu::Color.new(255, 200, 200, 200)
    )

    # Menu options
    @home_options.each_with_index do |option, index|
      color = index == @selected_option ? Gosu::Color::RED : Gosu::Color::BLACK
      @score_font.draw_text(
        option,
        width / 2 - 30,
        height / 2 + index * 50,
        1, 1, 1, color
      )
    end

    @score_font.draw_text(
      "Use ↑↓ to select, Enter to confirm",
      width / 2 - 150,
      height * 3/4,
      1, 1, 1, Gosu::Color::WHITE
    )
  end

  def draw_game_screen
    
    @background_texture.draw(
      0, 0, 0,
      width.to_f / @background_texture.width,
      height.to_f / @background_texture.height,
      
    )
    
    Gosu.draw_rect(
      @game_x_start, 0,
      @game_width, height,
      Gosu::Color.new(100, 200, 200, 200),
      1
    )


    @title_font.draw_text(
      "Stack Overflowed",
      width / 2 - 220, 20, 2,
      1, 1, Gosu::Color::BLACK
    )

   
    @score_font.draw_text(
      "Score: #{@score}",
      width / 2 - 50, 60, 2,
      1, 1, Gosu::Color::BLACK
    )

    
    @divs.each do |div|
      x = div[:actual_x] || case div[:actual_alignment]
          when :far_left then @game_x_start
          when :left then @game_x_start + @game_width / 7
          when :center_left then @game_x_start + (@game_width * 2) / 7
          when :center then @game_x_start + (@game_width - div[:width]) / 2
          when :center_right then @game_x_start + (@game_width * 4) / 7
          when :right then @game_x_start + (@game_width * 5) / 7
          when :far_right then @game_x_start + @game_width - div[:width]
          end

      
      @div_texture.draw(
        x,
        height - div[:y] - @div_height,
        2,
        div[:width].to_f / @div_texture.width,
        @div_height.to_f / @div_texture.height,
        div[:color]
      )

      
      font = Gosu::Font.new(self, Gosu.default_font_name, 20)
      font.draw_text(
        div[:alignment].to_s,
        x + div[:width] / 2 - 20,
        height - div[:y] - @div_height + 15,
        3,
        1, 1, Gosu::Color::WHITE
      )
    end

    
    if @current_div
      x = @descending ? 
        (@current_div[:actual_x] || case @current_div[:actual_alignment]
         when :far_left
           @game_x_start
         when :left
           @game_x_start + @game_width / 7
         when :center_left
           @game_x_start + (@game_width * 2) / 7
         when :center
           @game_x_start + (@game_width - @current_div[:width]) / 2
         when :center_right
           @game_x_start + (@game_width * 4) / 7
         when :right
           @game_x_start + (@game_width * 5) / 7
         when :far_right
           @game_x_start + @game_width - @current_div[:width]
         end) : 
        @current_div_x

      @div_texture.draw(
        x,
        @current_div_y,
        2,
        @current_div[:width].to_f / @div_texture.width,
        @div_height.to_f / @div_texture.height,
        @current_div[:color]
      )
    end

    # Draw flicker effect overlay
    if @flicker_duration > 0
      flash_opacity = (@flicker_duration.to_f / @flicker_max_duration * 100).to_i
      Gosu.draw_rect(
        0, 0, width, height,
        Gosu::Color.new(flash_opacity, 255, 255, 255),
        999  #z index
      )
    end

    # Game Over Screen
    if @game_over
      Gosu.draw_rect(
        0, 0, width, height,
        Gosu::Color.new(150, 0, 0, 0),
        100
      )
      @game_over_font.draw_text(
        "Game Over!",
        width / 2 - 170, height / 2 - 50,
        101, 1, 1, Gosu::Color::WHITE
      )
      @score_font.draw_text(
        "Final Score: #{@score}",
        width / 2 - 75, height / 2 + 20,
        101, 1, 1, Gosu::Color::WHITE
      )
      @score_font.draw_text(
        "Press R to Restart",
        width / 2 - 100, height / 2 + 70,
        101, 1, 1, Gosu::Color::YELLOW
      )
    end

    # Keyboard instructions
    instruction_font = Gosu::Font.new(self, Gosu.default_font_name, 20)
    instruction_font.draw_text(
      "SPACE to Place Div",
      width / 2 - 75, height - 50,
      2, 1, 1, Gosu::Color::BLACK
    )
  end
end


window = DivCenteringGame.new
window.show