require "io/console"

# I don't know how to get these key codes other than by hard-coding the
# ordinals
KEY_CTRL_C = 3.chr
KEY_DELETE = 127.chr
KEY_CTRL_W = 23.chr
KEY_CTRL_P = 16.chr
KEY_CTRL_N = 14.chr

class Options < Struct.new(:visible_choices)
end

class World
  attr_reader :choices, :index, :search_string

  def initialize(choices, index, search_string)
    @choices = choices
    @index = index
    @search_string = search_string
  end

  def self.blank(choices)
    new(choices, 0, "")
  end

  def done?
    false
  end

  def selected_choice
    @choices.fetch(@index)
  end

  def down
    index = [@index + 1, matches.count - 1, OPTIONS.visible_choices - 1].min
    World.new(choices, index, @search_string)
  end

  def up
    World.new(choices, [@index - 1, 0].max, @search_string)
  end

  def append_search_string(string)
    if string =~ /[[:print:]]/
      World.new(@choices, 0, @search_string + string)
    else
      self
    end
  end

  def backspace
    World.new(@choices, 0, @search_string[0...-1])
  end

  def delete_backward_word
    World.new(@choices, @index, @search_string.sub(/[^ ]* *$/, ""))
  end

  def matches
    re = search_string.split(//).map(&Regexp.method(:escape)).join('.*')
    re = /#{re}/
    @choices.select { |s| s =~ re }
  end

  def done
    Selection.new(matches.first)
  end
end

class TTY < Struct.new(:in_file, :out_file)
  def self.with_tty(&block)
    File.open("/dev/tty", "r") do |in_file|
      File.open("/dev/tty", "w") do |out_file|
        tty = TTY.new(in_file, out_file)
        block.call(tty)
      end
    end
  end

  def get_char
    in_file.getc
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

def handle_key(world, key)
  case key
  when KEY_CTRL_N then world.down
  when KEY_CTRL_P then world.up
  when KEY_DELETE then world.backspace
  when ?\r then world.done
  when KEY_CTRL_C then raise SystemExit
  when KEY_CTRL_W then world.delete_backward_word
  else world.append_search_string(key.chr)
  end
end

class Renderer < Struct.new(:world, :screen)
  def self.render!(world, screen)
    rendered = Renderer.new(world, screen).render
    start_line = screen.height - OPTIONS.visible_choices - 1
    screen.with_cursor_hidden do
      screen.write_lines(start_line, rendered.choices)
      screen.move_cursor(start_line, rendered.search_line.length)
    end
  end

  def render
    search_line = "> " + world.search_string
    matches = correct_match_count(world.matches)
    matches = matches.each_with_index.map do |match, index|
      if index == world.index
        Text[:red, match]
      else
        match
      end
    end
    choices = [search_line] + matches
    Rendered.new(choices, search_line)
  end

  def correct_match_count(matches)
    limited = matches[0, OPTIONS.visible_choices]
    padded = limited + [""] * (OPTIONS.visible_choices - limited.length)
    padded
  end

  class Rendered < Struct.new(:choices, :search_line)
  end
end

def main
  OPTIONS.visible_choices.times { puts }
  choices = $stdin.readlines.map(&:chomp)
  world = World.blank(choices)
  TTY.with_tty do |tty|
    Screen.with_screen(tty.out_file) do |screen|
      while not world.done?
        Renderer.render!(world, screen)
        world = handle_key(world, tty.get_char)
      end
      screen.move_cursor(screen.height - 1, 0)
    end
  end
  puts world.selection
end

class Screen
  def self.with_screen(file)
    screen = self.new(file)
    screen.configure_tty
    begin
      yield screen
    ensure
      screen.restore_tty
      file.puts
    end
  end

  attr_reader :file, :ansi

  def initialize(file)
    @file = file
    @ansi = ANSI.new(file)
    @original_stty_state = stty("-g")
  end


  def configure_tty
    # raw: Disable input and output processing
    # -echo: Don't echo keys back
    # cbreak: Set up lots of standard stuff, including INTR signal on ^C
    # dsusp undef: Unmap delayed suspend (^Y by default)
    stty("raw -echo cbreak dsusp undef")
    ansi.reset!
  end

  def restore_tty
    stty("#{@original_stty_state}")
    file.puts
  end

  def stty(args)
    command("stty -f #{file.path} #{args}")
  end

  def command(command)
    result = `#{command}`
    raise "Command failed: #{command.inspect}" unless $?.success?
    result
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
    ansi.hide_cursor!
    begin
      block.call
    ensure
      ansi.show_cursor!
    end
  end

  def height
    size[0]
  end

  def width
    size[1]
  end

  def size
    height, width = file.winsize
    [height, width]
  end

  def move_cursor(line, column)
    ansi.setpos!(line, column)
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
        ansi.setpos!(line, column)
        ansi.addstr!(component)
        column += component.length
      elsif component == :highlight
        highlight = true
      else
        color = component
        set_color(component, highlight)
      end
    end
    remaining_cols = width - column
    ansi.addstr!(" " * remaining_cols)
  end

  def set_color(color, highlight)
    ansi.color!(color, highlight ? :black : :default)
  end
end

class ANSI
  ESC = 27.chr

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def escape(sequence)
    ESC + "[" + sequence
  end

  def reset
    escape "2J"
  end

  def hide_cursor
    escape "?25l"
  end

  def show_cursor
    escape "?25h"
  end

  def setpos(line, column)
    escape "#{line + 1};#{column + 1}H"
  end

  def addstr(str)
    str
  end

  def color(fg, bg=:default)
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

  def reset!(*args); write reset(*args); end
  def setpos!(*args); write setpos(*args); end
  def addstr!(*args); write addstr(*args); end
  def color!(*args); write color(*args); end
  def hide_cursor!(*args); write hide_cursor(*args); end
  def show_cursor!(*args); write show_cursor(*args); end

  def write(bytes)
    file.write(bytes)
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

OPTIONS = Options.new(10)
main
