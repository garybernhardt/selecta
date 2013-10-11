require "io/console"

# I don't know how to get these key codes other than by hard-coding the
# ordinals
KEY_CTRL_C = 3.chr
KEY_DELETE = 127.chr
KEY_CTRL_W = 23.chr

class World
  attr_reader :lines, :search_string

  def initialize(lines, index, search_string)
    @lines = lines
    @index = index
    @search_string = search_string
  end

  def self.blank(options)
    new(options, 0, "")
  end

  def done?
    false
  end

  def selected_option
    @lines.fetch(@index)
  end

  def down
  end

  def up
  end

  def append_search_string(string)
    if string =~ /[[:print:]]/
      World.new(@lines, @index, @search_string + string)
    else
      self
    end
  end

  def backspace
    World.new(@lines, @index, @search_string[0...-1])
  end

  def delete_backward_word
    World.new(@lines, @index, @search_string.sub(/[^ ]* *$/, ""))
  end

  def matching_options
    re = search_string.split(//).map(&Regexp.method(:escape)).join('.*')
    re = /#{re}/
    @lines.select { |s| s =~ re }
  end

  def done
    Selection.new(matching_options.first)
  end
end

class Selection
  attr_reader :selection

  def initialize(selection)
    @selection = selection
  end

  def done?
    true
  end
end

def handle_key(world)
  key = $stdin.getc
  case key
  #when ?j then @cursor = @cursor.down
  #when ?k then @cursor = @cursor.up
  when KEY_DELETE then world.backspace
  when ?\r then world.done
  when KEY_CTRL_C then raise SystemExit
  when KEY_CTRL_W then world.delete_backward_word
  else world.append_search_string(key.chr)
  end
end

class Renderer < Struct.new(:world, :screen, :start_line)
  def render!
    rendered = render
    screen.with_cursor_hidden do
      screen.write_lines(start_line, rendered.lines)
      screen.move_cursor(*rendered.cursor_position)
    end
  end

  def render
    line_count = screen.height - start_line
    matching = world.matching_options[0, line_count - 1]
    matching += [""] * (line_count - matching.length)
    search_line = "> " + world.search_string
    lines = [search_line,
             Text[:red, matching[0]]] + matching[1..-1]
    Rendered.new(lines, [start_line, search_line.length])
  end

  class Rendered < Struct.new(:lines, :cursor_position)
  end
end

def main
  10.times { puts }
  source_file = ARGV.fetch(0)
  options = IO.readlines(source_file).map(&:chomp)
  world = World.blank(options)
  Screen.with_screen do |screen|
    start_line = screen.height - 10
    while not world.done?
      Renderer.new(world, screen, start_line).render!
      world = handle_key(world)
    end
    screen.move_cursor(screen.height - 1, 0)
  end
  puts world.selection
end

class Screen
  def self.with_screen
    screen = self.new
    screen.configure_tty
    begin
      yield screen
    ensure
      screen.restore_tty
      puts
    end
  end

  def initialize
    @original_stty_state = command("stty -g")
    @status_line = height - 3
    @highlight = false
  end


  def configure_tty
    # raw: Disable input and output processing
    # -echo: Don't echo keys back
    # cbreak: Set up lots of standard stuff, including INTR signal on ^C
    # dsusp undef: Unmap delayed suspend (^Y by default)
    command("stty raw -echo cbreak dsusp undef")
    ANSI.reset!
  end

  def restore_tty
    command("stty #{@original_stty_state}")
    puts
  end

  def suspend
    restore_tty
    begin
      yield
      configure_tty
    rescue
      restore_tty
    end
  end

  def with_cursor_hidden(&block)
    ANSI.hide_cursor!
    begin
      block.call
    ensure
      ANSI.show_cursor!
    end
  end

  def height
    size[0]
  end

  def width
    size[1]
  end

  def size
    height, width = $stdout.winsize
    [height, width]
  end

  def move_cursor(line, column)
    ANSI.setpos!(line, column)
  end

  def write_line(line, text)
    write(line, 0, text)
  end

  def write_lines(line, texts)
    texts.each_with_index do |text, index|
      write(line + index, 0, text)
    end
  end

  def write(line, column, text)
    # Discard writes outside the main screen area
    write_unrestricted(line, column, text) if line < height
  end

  def write_unrestricted(line, column, text)
    text = Text[:default, text] unless text.is_a? Text
    write_text_object(line, column,text)
  end

  def write_text_object(line, column, text)
    highlight = false
    text.components.each do |component|
      if component.is_a? String
        ANSI.setpos!(line, column)
        ANSI.addstr!(component)
        column += component.length
      elsif component == :highlight
        highlight = true
      else
        color = component
        set_color(component, highlight)
      end
    end
    remaining_cols = width - column
    ANSI.addstr!(" " * remaining_cols)
  end

  def set_color(color, highlight)
    ANSI.color!(color, highlight ? :black : :default)
  end

  def command(command)
    result = `#{command}`
    raise "Command failed: #{command.inspect}" unless $?.success?
    result
  end
end

module ANSI
  ESC = 27.chr

  def self.escape(sequence)
    ESC + "[" + sequence
  end

  def self.reset
    escape "2J"
  end

  def self.hide_cursor
    escape "?25l"
  end

  def self.show_cursor
    escape "?25h"
  end

  def self.setpos(line, column)
    escape "#{line + 1};#{column + 1}H"
  end

  def self.addstr(str)
    str
  end

  def self.color(fg, bg=:default)
    normal = "22"
    fg_codes = {
      :black => 30,
      :red => 31,
      :green => 32,
      :yellow => 33,
      :blue => 34,
      :magenta => 35,
      :cyan => 36,
      :white => 37,
      :default => 39,
    }
    bg_codes = {
      :black => 40,
      :red => 41,
      :green => 42,
      :yellow => 43,
      :blue => 44,
      :magenta => 45,
      :cyan => 46,
      :white => 47,
      :default => 49,
    }
    fg_code = fg_codes.fetch(fg)
    bg_code = bg_codes.fetch(bg)
    escape "#{normal};#{fg_code};#{bg_code}m"
  end

  def self.reset!(*args); write reset(*args); end
  def self.setpos!(*args); write setpos(*args); end
  def self.addstr!(*args); write addstr(*args); end
  def self.color!(*args); write color(*args); end
  def self.hide_cursor!(*args); write hide_cursor(*args); end
  def self.show_cursor!(*args); write show_cursor(*args); end

  def self.write(bytes)
    $stdout.write(bytes)
  end
end

class Text
  attr_reader :components

  def self.[](*args)
    new(args)
  end

  def initialize(components)
    @components = components
  end

  def ==(other)
    components == other.components
  end

  def +(other)
    Text[*(components + other.components)]
  end
end

main
