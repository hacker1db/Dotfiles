# Mini Plugins Test Guide

Open this file in Neovim to test all your mini plugins!

---

## 1. mini.comment - Comment toggling

### Test on this code block:
```lua
local function hello()
    print("Hello World")
    return true
end
```

**Try these:**
- Put cursor on line 2 → press `gcc` (should comment/uncomment the line)
- Visual select lines 2-4 → press `gc` (should comment/uncomment selection)
- Press `gcip` while cursor in function (should comment entire paragraph)

---

## 2. mini.pairs - Auto-pairing

### Test in insert mode:
Type these characters and watch them auto-complete:

1. Type `{` → should auto-close to `{}`
2. Type `(` → should auto-close to `()`
3. Type `"` → should auto-close to `""`
4. Type `'` → should auto-close to `''`

**Test area (go into insert mode below):**


---

## 3. mini.surround - Surround operations

### Test on these words:

hello
world
test

**Try these:**
1. Put cursor on "hello" → type `saiw"` (should surround word with quotes: "hello")
2. Put cursor inside quotes → type `sd"` (should delete quotes)
3. Put cursor on quoted word → type `sr"(` (should replace quotes with parens)
4. Put cursor on word → type `saiwt<div>` (should surround with <div></div>)

---

## 4. mini.ai - Better text objects

### Test on this function:
```javascript
function calculateSum(a, b) {
    const result = a + b;
    return result;
}
```

**Try these:**
1. Put cursor anywhere in function → type `dif` (delete inside function)
2. Put cursor in quotes → type `ci"` (change inside quotes)
3. Put cursor in parentheses → type `di(` (delete inside parentheses)
4. Type `vaf` (visual select around function)

### Test next/last variants:
```python
def first():
    pass

def second():
    pass

def third():
    pass
```

**From the top:**
- Type `]f` → jumps to next function
- Type `[f` → jumps to previous function
- Type `inf` → select inside next function
- Type `anf` → select around next function

---

## 5. blink.cmp - Completion testing

### Test LSP completions:
Start typing in a lua file and test these keybindings:

**In insert mode:**
- `<C-k>` → previous suggestion
- `<C-j>` → next suggestion  
- `<C-Space>` → show completions
- `<CR>` → accept completion
- `<C-e>` → close completion menu
- `<Tab>` → next snippet field
- `<S-Tab>` → previous snippet field

### Test these sources:
1. **LSP**: Type `vim.` and see Neovim API completions
2. **Path**: Type `./` and see file path completions
3. **Buffer**: Type words that exist elsewhere in this file
4. **Emoji**: Type `:smile` and see emoji completions
5. **Spell**: Misspell a word and see spell corrections
6. **Snippets**: Type `for` and see snippet completions

---

## Quick Reference Card

| Plugin | Keybind | Action |
|--------|---------|--------|
| **mini.comment** | `gcc` | Toggle line comment |
| | `gc` (visual) | Toggle selection comment |
| | `gcip` | Comment paragraph |
| **mini.surround** | `sa` | Add surrounding |
| | `sd` | Delete surrounding |
| | `sr` | Replace surrounding |
| | `sf` | Find surrounding (right) |
| **mini.ai** | `dif` | Delete inside function |
| | `vaf` | Select around function |
| | `ci"` | Change inside quotes |
| | `]f` / `[f` | Next/prev function |
| **blink.cmp** | `<C-j>` / `<C-k>` | Next/prev completion |
| | `<CR>` | Accept completion |
| | `<C-Space>` | Show completions |

---

## Success Criteria

✅ mini.comment - Comments toggle correctly  
✅ mini.pairs - Brackets/quotes auto-close  
✅ mini.surround - Can add/delete/replace surroundings  
✅ mini.ai - Text objects work (dif, vaf, etc.)  
✅ blink.cmp - Completions appear and keybinds work  

Happy testing! 🎉
