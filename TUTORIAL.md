# Vim Motions & Dotfiles Tutorial

> **Tip:** Use `:help {topic}` inside vim to get built-in documentation on any command, motion, or option. It's the single most useful thing to learn.

## 1. Vim Motions Cheat Sheet

### Navigation

| Key | Action |
|-----|--------|
| `h` `j` `k` `l` | Left / Down / Up / Right |
| `w` `b` `e` | Next word / Back word / End of word |
| `W` `B` `E` | Same as above, WORD (whitespace-delimited) |
| `0` `$` | Start / End of line |
| `^` | First non-blank character |
| `gg` `G` | Top / Bottom of file |
| `42G` | Go to line 42 |
| `f{c}` `t{c}` | Jump to / Jump before character {c} |
| `F{c}` `T{c}` | Same, backwards |
| `;` `,` | Repeat / Reverse last f/t jump |
| `%` | Jump to matching bracket |
| `{` `}` | Previous / Next blank line (paragraph) |
| `Ctrl-d` `Ctrl-u` | Half-page down / up |
| `H` `M` `L` | Top / Middle / Bottom of screen |

### Window Management

| Key | Action |
|-----|--------|
| `Ctrl-w s` | Split horizontally |
| `Ctrl-w v` | Split vertically |
| `Ctrl-w w` | Cycle between splits |
| `Ctrl-w h/j/k/l` | Navigate to split |
| `Ctrl-w =` | Equalize split sizes |
| `Ctrl-w _` / `Ctrl-w \|` | Maximize height / width |
| `Ctrl-w q` | Close split |

### Editing

| Key | Action |
|-----|--------|
| `i` `a` | Insert before / after cursor |
| `I` `A` | Insert at start / end of line |
| `o` `O` | Open line below / above |
| `d` `c` `y` | Delete / Change / Yank (operator) |
| `p` `P` | Paste after / before |
| `x` | Delete character |
| `r{c}` | Replace character with {c} |
| `~` | Toggle case |
| `u` `Ctrl-r` | Undo / Redo |
| `.` | Repeat last change |
| `J` | Join lines |

### Operators + Motions

| Command | Action |
|---------|--------|
| `dw` | Delete word |
| `d$` / `D` | Delete to end of line |
| `dd` | Delete entire line |
| `ci"` | Change inside quotes |
| `ca(` | Change around parentheses |
| `yap` | Yank a paragraph |
| `dip` | Delete inside paragraph |
| `dit` | Delete inside tag |
| `gUiw` | Uppercase word |

Text objects: `i`(inside) / `a`(around) + `w`(word) `s`(sentence) `p`(paragraph) `"` `'` `` ` `` `(` `{` `[` `<` `t`(tag)

### Visual Mode

| Key | Action |
|-----|--------|
| `v` | Character-wise visual |
| `V` | Line-wise visual |
| `Ctrl-v` | Block (column) visual |
| `gv` | Reselect last visual selection |
| `o` | Jump to other end of selection |

### Search & Replace

| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` `N` | Next / Previous match |
| `*` `#` | Search word under cursor forward / backward |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirmation |

### Marks, Registers, Macros

| Key | Action |
|-----|--------|
| `m{a-z}` | Set mark |
| `` `{a-z} `` | Jump to mark |
| `"{a-z}y` | Yank into register |
| `"{a-z}p` | Paste from register |
| `"0p` | Paste last yank (not delete) |
| `q{a-z}` | Record macro |
| `q` | Stop recording |
| `@{a-z}` | Play macro |
| `@@` | Repeat last macro |

---

## 2. Guided Exercises

### Practice File

Copy the text below into a file (`vim /tmp/practice.txt`) and use it for the exercises:

```
function greetUser(name) {
    const message = "Hello, world!"
    console.log(message)
    return { status: "ok", user: name }
}

function processItems(items) {
    const results = []
    for (const item of items) {
        results.push(item.toUpperCase())
    }
    return results
}

const config = {
    host: "localhost",
    port: 8080,
    debug: true,
    verbose: false,
    timeout: 3000,
}

// TODO: refactor this
// TODO: add error handling
// TODO: write tests
```

### Beginner

Motions used: [Navigation](#navigation), [Editing](#editing)

1. **Go to line 5 and delete the word `status`**
   `5G f" l dw` — Verify: line reads `return { : "ok", user: name }`

2. **Delete from cursor to end of line 2**
   `2G f" D` — Verify: line reads `    const message = `

3. **Yank line 3, paste it below, then change `log` to `warn`**
   `3G yy p f. l cw` type `warn` `Escape` — Verify: new line reads `console.warn(message)`

4. **Move down 10 lines from line 1**
   `gg 10j` — Verify: cursor is on line 11 (`results.push...`)

5. **Delete the 3 TODO comment lines at the bottom**
   `G k k 3dd` — Verify: file ends after the `}` closing config

### Intermediate

Motions used: [Operators + Motions](#operators--motions), [Visual Mode](#visual-mode), [Search & Replace](#search--replace)

6. **Change `"Hello, world!"` to `"Hi there!"` (line 2)**
   `2G f" ci"` type `Hi there!` `Escape` — Verify: quotes are preserved, content changed

7. **Select the `processItems` function body and indent it**
   Navigate inside the function, `vap >` — Verify: block is indented one level

8. **Delete everything inside the parentheses on line 1**
   `gg f( di(` — Verify: line reads `function greetUser()`

9. **Replace all occurrences of `function` with `const` using search**
   `:%s/function/const/g` — Verify: both function declarations changed

10. **Copy the config object's contents (inside braces) and paste below**
    Navigate to config's `{`, `yi{` `G o` `Escape` `p` — Verify: key-value pairs pasted at end

11. **Uppercase the word `localhost` on the host line**
    `/localhost` `Enter` `gUiw` — Verify: reads `"LOCALHOST"`

12. **Move the `debug: true` line below `timeout: 3000`**
    Navigate to `debug` line, `dd` then navigate to `timeout` line, `p` — Verify: debug line is after timeout

### Advanced

Motions used: [Marks, Registers, Macros](#marks-registers-macros), [Window Management](#window-management)

13. **Record a macro to wrap each config value line in a comment, run it on 5 lines**
    Navigate to first config value, `qa I// ` `Escape` `j q 4@a` — Verify: 5 lines are commented out

14. **Replace `port` with `PORT` only in lines 17-22**
    `:17,22s/port/PORT/g` — Verify: only the config block is affected

15. **Prepend `export ` to each config key using block visual**
    Navigate to config keys, `Ctrl-v` select the column down 5 lines, `I` type `export ` `Escape` — Verify: each line starts with `export `

16. **Sort the config keys alphabetically**
    Select the key-value lines with `V` then select down, `:sort` `Enter` — Verify: keys are in alphabetical order

17. **Delete every other TODO line using a macro**
    Navigate to first TODO, `qa dd j q @a` — Verify: alternating lines deleted

---

## 3. Dotfiles Workflow Reference

Custom keybindings from this repo's configuration files. Source file paths are relative to the dotfiles root.

### Neovim

Source: `nvim/init.lua`

Leader key: **Space**

#### Fuzzy Finding — telescope.nvim

| Key | Action |
|-----|--------|
| `Space f` | Find files |
| `Space g` | Live grep |
| `Space b` | List buffers |
| `Space h` | Help tags |

#### LSP — nvim-lspconfig

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Hover documentation |
| `Space r` | Rename symbol |
| `Space a` | Code action |
| `Space d` | Open diagnostic float |

#### General

| Key | Action |
|-----|--------|
| `Space w` | Save file |
| `Space q` | Quit |
| `Space x` | Close buffer |
| `Escape` | Clear search highlight |
| `Ctrl-d` | Scroll down + center |
| `Ctrl-u` | Scroll up + center |

#### Visual Mode

| Key | Action |
|-----|--------|
| `J` | Move selection down |
| `K` | Move selection up |
| `<` | Indent left (reselects) |
| `>` | Indent right (reselects) |

#### Treesitter Selection — nvim-treesitter

| Key | Action |
|-----|--------|
| `Ctrl-Space` (normal) | Start incremental selection |
| `Ctrl-Space` (visual) | Expand selection |
| `Backspace` (visual) | Shrink selection |

#### Completion — nvim-cmp

| Key | Action |
|-----|--------|
| `Ctrl-n` / `Ctrl-p` | Next / Previous item |
| `Ctrl-d` / `Ctrl-u` | Scroll docs down / up |
| `Enter` | Confirm selection |
| `Ctrl-Space` | Trigger completion |

### Tmux

Source: `tmux/tmux.conf`

#### Pane Navigation

| Key | Action |
|-----|--------|
| `prefix + h/j/k/l` | Select pane (vim-style) |
| `Alt + Arrow keys` | Select pane (no prefix) |

#### Window Navigation

| Key | Action |
|-----|--------|
| `Shift-Left` / `Shift-Right` | Previous / Next window |
| `Alt-H` / `Alt-L` | Previous / Next window |

#### Splits

| Key | Action |
|-----|--------|
| `prefix + "` | Split vertically (current path) |
| `prefix + %` | Split horizontally (current path) |

#### Vi Copy Mode

Enter copy mode with `prefix + [`, then:

| Key | Action |
|-----|--------|
| `v` | Begin selection |
| `Ctrl-v` | Toggle rectangle selection |
| `y` | Copy selection and exit copy mode |

### Zsh

Source: `zsh/.config/zsh/04-keybindings.zsh`

#### Word & Line Navigation

| Key | Action |
|-----|--------|
| `Option + Right/Left` | Forward / Backward word |
| `Ctrl-A` | Beginning of line |
| `Ctrl-E` | End of line |

#### History

| Key | Action |
|-----|--------|
| `Ctrl-R` | Search history backward |
| `Ctrl-S` | Search history forward |
| `Ctrl-P` / `Ctrl-N` | Previous / Next history (with search) |

#### FZF — sourced via `zsh/.config/zsh/02-plugins.zsh`

| Key | Action |
|-----|--------|
| `Ctrl-T` | Paste selected file path |
| `Ctrl-R` | Fuzzy search command history (overrides default) |
| `Alt-C` | cd into selected directory |

#### Aliases

| Alias | Action |
|-------|--------|
| `work` | Attach or create a tmux session named "work" |

### Cross-Tool Integration

The **vim-tmux-navigator** plugin (configured in both `nvim/init.lua` and `tmux/tmux.conf`) provides seamless pane/split switching:

| Key | Action |
|-----|--------|
| `Ctrl-h` | Navigate left |
| `Ctrl-j` | Navigate down |
| `Ctrl-k` | Navigate up |
| `Ctrl-l` | Navigate right |

These keys work identically whether the cursor is in a neovim split or a tmux pane. The plugin must be installed on both sides for this to work.

### Troubleshooting

- **`Ctrl-S` freezes the terminal** — Your terminal has flow control enabled. Add `stty -ixon` to your `.zshrc` (or run it once) to disable it. `Ctrl-Q` unfreezes if you're stuck.
- **`Ctrl-h/j/k/l` doesn't cross between vim and tmux** — Ensure vim-tmux-navigator is installed in both neovim (plugin) and tmux (TPM plugin or manual snippet in `tmux.conf`).
- **Option key doesn't work for word navigation in zsh** — In iTerm2/Terminal.app, set the Option key to send `Esc+` (Meta) in the profile's key settings.
