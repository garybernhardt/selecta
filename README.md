# Selecta

Selecta is a fuzzy selector. You can use it for fuzzy selection in the style of
Command-T, ctrlp, etc. You can also use it to fuzzy select anything else:
command names, help topics, identifiers; anything you have a list of.

I wrote it to select things from vim, but it has no dependency on vim at all.
Its interface is dead simple:

* Pass it a list of choices on stdin.
* It will present a pretty standard fuzzy selection interface to the user (and
  block until they make a selection or kill it).
* It will print the user's selection on stdout.

For example, you can say:

```
cat $(ls *.txt | selecta)
```

which will prompt the user to fuzzy-select one of the text files in the current
directory, then print the contents of whichever one they choose. It looks like
this:

![Demo](https://raw.github.com/garybernhardt/selecta/master/demo.gif)

Selecta does not:

- Read from or write to the disk.
- Know about any editors (including vim).
- Know what it's searching.
- Perform any actions on the item you select.

It supports these keys:

- ^W to delete the word before the cursor
- ^H to delete the character before the cursor
- ^U to delete the entire line
- ^N to select the next match
- ^P to select the previous match
- ^C to quit without selecting a match

Ranking algorithm:

- Select each input string that contains all of the characters in the query.
  They must be in order, but don't have to be sequential. Case is ignored.
  ("ct" will match "cat" and "Crate", but not "tack".)
- Shorter match substrings rank higher (when searching for "ct", "cat" ranks
  higher than "crate" because "cat" is shorter than "crat", which is the part
  of "crate" that matches).
- Shorter overall strings match higher ("foo.rb" ranks higher than
  "foo_spec.rb").

## Installation

Selecta requires Ruby 1.9.3 or better.

For now, copy the `selecta` script to your path. ~/bin is a great place for it.
If you don't currently have a ~/bin, just do `mkdir ~/bin` and add
`export PATH="$HOME/bin:$PATH"` to your .zshrc, .bashrc, etc.

Selecta is *not installable as a gem*! Gems are only good for
application-specific tools. You want Selecta available at all times. If it were
a gem, it would sometimes disappear when you said `rvm use`.

## Use with Vim

There's no actual vim plugin yet. It may not end up needing one; we'll see. For
now, you can just stick the code below in your .vimrc to invoke Selecta with
`<leader>f` (this will be `\f` unless you've changed your leader). Note that
Selecta has to run in a terminal by its nature, so this Vim example will not
work in graphical Vims like MacVim.

```vimscript
" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! SelectaCommand(choice_command, selecta_args, vim_command)
  try
    silent let selection = system(a:choice_command . " | selecta " . a:selecta_args)
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

## Examples

### Check out a git branch

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

### Search for files based on identifier under the cursor in Vim

When you put your cursor anywhere in the word "User" and press `<c-g>`, this
mapping will open Selecta with the search box pre-populated with "User". It's
an quick and dirty way to find files related to an identifier.

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

### Switch to a project

You can use Selecta to write a simple shell function that will allow you to
quickly switch to a particular project's directory. For example, supposing you
have projects under both ~/rails-projects and ~/django-projects:

```shell
proj() {
    cd $(find ~/rails-projects ~/django-projects -maxdepth 1 -type d | selecta)
}
```

## FAQ

**Won't this be slow?**

Nope: startup and termination together burn about 23 ms of CPU on my machine (a
mid-2011 MacBook Air). File finding may be slow, but, speaking of that...

**What about caching, selecting only certain file types, etc.?**

Those are different problems. This is just a simple fuzzy finding user
interface. It could be combined with caching, etc. I don't use caching myself,
prefering to keep repos small, so no-caching was a design requirement.
