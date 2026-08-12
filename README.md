# 🦀 crisp-mode.el — Emacs Major Mode for CRISP

[![License](https://img.shields.io/badge/License-GPLv3+%20-blue.svg)](LICENSE)
[![Emacs](https://img.shields.io/badge/Emacs-27.1+-purple.svg)](https://www.gnu.org/software/emacs/)
[![Version](https://img.shields.io/badge/Version-0.1.7-brightgreen.svg)](https://github.com/CRISP-lang-foundation/crisp-mode)

**crisp-mode** is an Emacs major mode for editing **CRISP** source files (`.csp`, `.crisp`).

---

## ✨ Features

- Syntax highlighting (keywords, builtins, types, strings, comments, sigils)
- Smart indentation (if, while, for, match, try/catch blocks)
- Auto-indent on Enter (`RET`)
- Template insertion (`C-c i f/w/F/n/c/t`)
- Sigil insertion (`C-c $`)
- Region evaluation (`C-c C-c`)
- Imenu support
- Tree-Sitter support (Emacs 29+, optional)

---

## 🚀 Quick Install

```bash
git clone https://github.com/CRISP-lang-foundation/crisp-mode.git
cp crisp-mode.el ~/.emacs.d/lisp/
```

### `use-package`

```elisp
(use-package crisp-mode
  :load-path "~/.emacs.d/lisp/"
  :mode ("\\.csp\\'" "\\.crisp\\'" . crisp-mode))
```

---

## ⌨️ Keybindings

| Key | Action |
|-----|--------|
| `RET` | Auto-indent newline |
| `C-c i f` | Insert `if` statement |
| `C-c i w` | Insert `while` loop |
| `C-c i F` | Insert `for` loop |
| `C-c i n` | Insert `fn` function |
| `C-c i c` | Insert `class` |
| `C-c i t` | Insert `try`/`catch` |
| `C-c C-c` | Evaluate region |
| `C-c $` | Insert sigil |

---

## 🔧 Customization

```elisp
(setq crisp-indent-offset 4)           ;; Spaces per indent level
(setq crisp-use-tree-sitter nil)       ;; Enable Tree-Sitter (Emacs 29+)
(setq crisp-auto-indent t)             ;; Auto-indent on Enter
```

---

## 📝 Example

```crisp
# hello.csp
say "Hello, World!";

fn greet(name) {
    say "Hello, " + name + "!";
}

class Animal {
    fn new(name) {
        self.name = name;
    }
}
```

---

## 🤝 Contributing

1. Fork → Feature branch → PR
2. Report issues on [GitHub Issues](https://github.com/CRISP-lang-foundation/CRISP-mode-el/issues)

---

## 📄 License

GPLv3+ - [LICENSE](https://github.com/CRISP-lang-foundation/CRISP-mode-el/blob/main/LICENSE)

---

## 🔗 Links
- [CRISP Book](https://github.com/CRISP-lang-foundation/CRISP-book)
- [CRISP Language](https://github.com/CRISP-lang-foundation/CRISP-lang)

---

**🦀 Perl's expressiveness · Rust's safety**
