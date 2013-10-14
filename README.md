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
- Change the order of the choices piped in. (But you can always put a `| sort
  |` in your pipeline if you want them sorted.)

It supports these keys:

- ^W to delete the word before the cursor
- ^N to select the next match
- ^P to select the previous match
- ^C to quit without selecting a match

## Installation

Selecta requires Ruby 1.9 or better.

For now, copy the `selecta` script to your path. ~/bin is a great place for it.
If you don't currently have a ~/bin, just do `mkdir ~/bin` and add
`export PATH="$HOME/bin:$PATH"` to your .zshrc, .bashrc, etc.

Selecta is *not installable as a gem*! Gems are only good for
application-specific tools. You want Selecta available at all times. If it were
a gem, it would sometimes disappear when you said `rvm use`.

## Use with Vim

There's no actual vim plugin yet. It may not end up needing one; we'll see. For
now, you can just stick this in your .vimrc:

```vimscript
" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! SelectaCommand(choice_command, vim_command)
  try
    silent! exec a:vim_command . " " . system(a:choice_command . " | selecta")
  catch /Vim:Interrupt/
    " Swallow the ^C so that the redraw below happens; otherwise there will be
    " leftovers from selecta on the screen
  endtry
  redraw!
endfunction

" Find all files in all non-dot directories starting in the working directory.
" Fuzzy select one of those. Open the selected file with :e.
map <leader>f :call SelectaCommand("find * -type f", ":e")<cr>
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

### Open tags in Vim

Suppose you use ctags, and want to fuzzy-select from them. This shell command
will give you a list of tags:

```shell
awk '{print $1}' tags | sort -u | grep -v '^!'
```

(The grep removes the tag file headers.)

Now that we have a tag list, we can use the Vim function from earlier. The Vim
command will be `:tag`, to jump to whichever tag we select. The shell command
above will generate the options. Putting those together:

```vimscript
" Find all tags in the tags database, then open the tag that the user selects
command! SelectaTag :call SelectaCommand("awk '{print $1}' tags | sort -u | grep -v '^!'", ":tag")
map <leader>t :SelectaTag<cr>
```

Now, when you hit `<leader>t`, it will prompt you to fuzzy-select a
function/class/whatever, then will jump to the definition of that object.

## FAQ

**Won't this be slow?**

Nope: startup and termination together burn about 23 ms of CPU on my machine (a
mid-2011 MacBook Air). File finding may be slow, but, speaking of that...

**What about caching, selecting only certain file types, etc.?**

Those are different problems. This is just a simple fuzzy finding user
interface. It could be combined with caching, etc. I don't use caching myself,
prefering to keep repos small, so no-caching was a design requirement.
