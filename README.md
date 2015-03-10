# Selecta

Selecta is a fuzzy selector. You can use it for fuzzy selection in the style of
Command-T, ctrlp, etc. You can also use it to fuzzy select anything else:
command names, help topics, identifiers; anything you have a list of.

It was originally written to select things from vim, but it has no dependency
on vim at all and is used for many other purposes. Its interface is dead
simple:

* Pass it a list of choices on stdin.
* It will present a pretty standard fuzzy selection interface to the user (and
  block until they make a selection or kill it with ^C).
* It will print the user's selection on stdout.

For example, you can say:

```
cat $(ls *.txt | selecta)
```

which will prompt the user to fuzzy-select one of the text files in the current
directory, then print the contents of whichever one they choose. It looks like
this:

![Demo](https://raw.github.com/garybernhardt/selecta/master/demo.gif)

Selecta supports these keys:

- ^W to delete the word before the cursor
- ^H to delete the character before the cursor
- ^U to delete the entire line
- ^N to select the next match
- ^P to select the previous match
- ^C to quit without selecting a match

## Theory of Operation

Selecta is unusual in that it's a filter (it reads from/to stdin/stdout), but
it's also an interactive program (it accepts user keystrokes and draws a UI).
It directly opens `/dev/tty` to do the latter.

With that exception aside, Selecta is a normal, well-behaved Unix tool. If a
selection is made, the line will be written to stdout with a single trailing
newline. If no selection is made (meaning the user killed Selecta with ^C), it
will write nothing to stdout and exit with status code 1.

Because it's just a filter program, Selecta doesn't know about any other tools.
Specifically, it does not:

- Read from or write to the disk.
- Know about any editors (including vim).
- Know what it's searching.
- Perform any actions on the item you select.

The ranking algorithm is:

- Select each input string that contains all of the characters in the query.
  They must be in order, but don't have to be sequential. Case is ignored.
- The score is the length of the matching substring. Lower is better.
- If a character is on a word boundary, it only contributes 1 to the length, rather than the actual number of characters since the previous matching character. Querying "app/models" for "am" gives a score of 2, not 5.
- Bonus for exact queries: when several adjacent characters match sequentially, only the first two score. Querying "search_spec.rb" for "spec" gives a score of 2, not 4.
- Bonus for acronyms: when several sequential query characters exist on word boundaries, only the first two score. Querying "app/models/user.rb" for "amu" gives a score of 2, not 3.

Some concrete examples:
- "ct" will match "cat" and "Crate", but not "tack".
- "le" will match "lend" and "ladder". "lend" will appear higher in the results
  because the matching substring is shorter ("le" vs. "ladde").

## Installation

Selecta requires Ruby 1.9.3 or better.

To install on your Mac using [Homebrew](http://brew.sh), say:

```shell
brew install selecta
```

For other systems, copy the `selecta` script to your path. ~/bin is a great
place for it. If you don't currently have a ~/bin, just do `mkdir ~/bin` and
add `export PATH="$HOME/bin:$PATH"` to your .zshrc, .bashrc, etc.

Selecta is *not installable as a Ruby gem*! Gems are only good for
application-specific tools. You want Selecta available at all times. If it were
a gem, it would sometimes disappear when switching Rubies, gemsets, etc.

## Use with Vim

There's no vim plugin. It may not end up needing one; we'll see. For now, you
can just stick the code below in your .vimrc to invoke Selecta with `<leader>f`
(this will be `\f` unless you've changed your leader). Note that Selecta has to
run in a terminal by its nature, so this Vim example will not work in graphical
Vims like MacVim.

```vimscript
" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! SelectaCommand(choice_command, selecta_args, vim_command)
  try
    let selection = system(a:choice_command . " | selecta " . a:selecta_args)
  catch /Vim:Interrupt/
    " Swallow the ^C so that the redraw below happens; otherwise there will be
    " leftovers from selecta on the screen
    redraw!
    return
  endtry
  redraw!
  exec a:vim_command . " " . selection
endfunction

" Find all files in all non-dot directories starting in the working directory.
" Fuzzy select one of those. Open the selected file with :e.
nnoremap <leader>f :call SelectaCommand("find * -type f", "", ":e")<cr>
```

You can also use selecta to open buffers. Just add the following to your .vimrc, as well as the `SelectaCommand` function above:

```vimscript
function! SelectaBuffer()
  let bufnrs = filter(range(1, bufnr("$")), 'buflisted(v:val)')
  let buffers = map(bufnrs, 'bufname(v:val)')
  call SelectaCommand('echo "' . join(buffers, "\n") . '"', "", ":b")
endfunction

" Fuzzy select a buffer. Open the selected buffer with :b.
nnoremap <leader>b :call SelectaBuffer()<cr>
```

## Usage Examples

#### Check out a git branch

```
$ git branch | cut -c 3- | selecta | xargs git checkout
```

When you say `git branch`, you get something like this:

```
* master
  mytopic
  release
```

The `cut` removes those first two columns. Then we just select a branch and use
it as an argument to `git checkout`.

#### Search for files based on identifier under the cursor in Vim

When you put your cursor anywhere in the word "User" and press `<c-g>`, this
mapping will open Selecta with the search box pre-populated with "User". It's
a quick and dirty way to find files related to an identifier.

```vimscript
function! SelectaIdentifier()
  " Yank the word under the cursor into the z register
  normal "zyiw
  " Fuzzy match files in the current directory, starting with the word under
  " the cursor
  call SelectaCommand("find * -type f", "-s " . @z, ":e")
endfunction
nnoremap <c-g> :call SelectaIdentifier()<cr>
```

#### Switch to a project

You can use Selecta to write a simple shell function that will allow you to
quickly switch to a particular project's directory. For example, supposing you
have projects under both ~/rails-projects and ~/django-projects:

```shell
proj() {
    cd $(find ~/rails-projects ~/django-projects -maxdepth 1 -type d | selecta)
}
```

#### Insert fuzzy-found paths directly into the shell command line

This only works with zsh (patches to make it work with Bash would be
appreciated). Put it in your ~/.zshrc. Then, whenever you press ^S, zsh will
run `find * -type f | selecta` and append the resulting selected path to the
current command line.

Caveats: 1) You're running `find` in the current working directory. If you do
it in a large directory, like ~, then it's going to take a while. 2) This also
disables flow control to free up the ^S keystroke. If you normally use ^S and
^Q, you may want to map to a different key and remove the `unsetopt
flowcontrol`.

```shell
# By default, ^S freezes terminal output and ^Q resumes it. Disable that so
# that those keys can be used for other things.
unsetopt flowcontrol
# Run Selecta in the current working directory, appending the selected path, if
# any, to the current command, followed by a space.
function insert-selecta-path-in-command-line() {
    local selected_path
    # Print a newline or we'll clobber the old prompt.
    echo
    # Find the path; abort if the user doesn't select anything.
    selected_path=$(find * -type f | selecta) || return
    # Append the selection to the current command buffer.
    eval 'LBUFFER="$LBUFFER$selected_path "'
    # Redraw the prompt since Selecta has drawn several new lines of text.
    zle reset-prompt
}
# Create the zle widget
zle -N insert-selecta-path-in-command-line
# Bind the key to the newly created widget
bindkey "^S" "insert-selecta-path-in-command-line"
```

#### Select a process by name and insert its pid into the command line

This is a variant of the previous technique that is useful any time you need to
find a pid: attaching a debugger, sending a signal, killing a process, and the
like.

```shell
function select-pid() {
    local selected_path
    echo
    selected_path=$(ps axww -o pid,user,%cpu,%mem,start,time,command | selecta | sed 's/^ *//' | cut -f1 -d' ')
    eval 'LBUFFER="$LBUFFER$selected_path "'
    zle reset-prompt
}

zle -N select-pid
bindkey "^Y" "select-pid"
```

## FAQ

**Won't this be slow?**

Nope: startup and termination together burn about 23 ms of CPU on my machine (a
mid-2011 MacBook Air). File finding may be slow, but, speaking of that...

**What about caching, selecting only certain file types, etc.?**

Those are different problems. This is just a simple fuzzy finding user
interface. It could be combined with caching, etc. I don't use caching myself,
prefering to keep repos small. Selecta was partially motivated by frustration
with existing fuzzy file finders, which occasionally showed incorrect results
with caching turned on but were painfully slow with caching disabled.
