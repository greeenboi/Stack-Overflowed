require 'gosu'

class GameWindow < Gosu::Window
  def initialize(width=720, height=1080, fullscreen=false)
    super
    self.caption = 'Hello'
    #@message = Gosu::Image.from_text(self,'Hello World bruh!', Gosu.default_font_name, 30)
    @x = @y = 10
    @draws = 0
    @buttons_down = 0
  end

  def update
    @x -= 1 if button_down?(Gosu::KbLeft)

  def draw
    @message.draw(10,10,0)
  end
end

window = GameWindow.new
window.show
