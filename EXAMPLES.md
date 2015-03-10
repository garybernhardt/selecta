# Selecta Examples

## Vim: Open a buffer

```vimscript
function! SelectaBuffer()
  let bufnrs = filter(range(1, bufnr("$")), 'buflisted(v:val)')
  let buffers = map(bufnrs, 'bufname(v:val)')
  call SelectaCommand('echo "' . join(buffers, "\n") . '"', "", ":b")
endfunction

" Fuzzy select a buffer. Open the selected buffer with :b.
nnoremap <leader>b :call SelectaBuffer()<cr>
```

## Vim: Search for files based on identifier under the cursor

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

## Git: Check out a branch

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

## Shells: Switch to a project

You can use Selecta to write a simple shell function that will allow you to
quickly switch to a particular project's directory. For example, supposing you
have projects under both ~/rails-projects and ~/django-projects:

```shell
proj() {
    cd $(find ~/rails-projects ~/django-projects -maxdepth 1 -type d | selecta)
}
```

## Zsh: Insert fuzzy-found paths directly into the shell command line

Put this in your ~/.zshrc. Then, whenever you press ^S, zsh will run `find *
-type f | selecta` and append the resulting selected path to the current
command line.

Caveats: 1) You're running `find` in the current working directory. If you do
it in a large directory, like ~, then it's going to take a while. 2) This also
disables flow control to free up the ^S keystroke. If you normally use ^S and
^Q, you may want to map to a different key and remove the `unsetopt
flowcontrol`. (You probably don't use these keys; few people do.)

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
