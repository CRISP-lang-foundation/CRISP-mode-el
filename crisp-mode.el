;;; crisp-mode.el --- Major mode for editing CRISP source files -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Peter Leukanič

;; Author: Peter Leukanič
;; Version: 0.1.7
;; Package-Requires: ((emacs "27.1"))
;; Keywords: languages, crisp

;;; Commentary:

;; CRISP mode provides syntax highlighting, indentation, and basic editing
;; support for the CRISP programming language.

;; Features:
;; - Syntax highlighting (font-lock)
;; - Smart indentation
;; - Auto-indent on Enter
;; - Template insertion (if, while, for, fn, class, try/catch, match)
;; - Imenu support (functions and classes)
;; - Tree-sitter support (optional, Emacs 29+)

;;; Code:

;; --- User Customization --------------------------------------------------

(defgroup crisp nil
  "Major mode for editing CRISP source code."
  :group 'languages
  :prefix "crisp-")

(defcustom crisp-indent-offset 4
  "Number of spaces for each indentation level in CRISP mode."
  :type 'integer
  :group 'crisp)

(defcustom crisp-use-tree-sitter nil
  "Whether to use tree-sitter for CRISP mode (Emacs 29+ only)."
  :type 'boolean
  :group 'crisp)

;; --- Syntax Table ---------------------------------------------------------

(defvar crisp-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Comments
    (modify-syntax-entry ?#  "<"   table)
    (modify-syntax-entry ?\n ">"   table)
    ;; Strings
    (modify-syntax-entry ?\" "\""  table)
    (modify-syntax-entry ?\' "\""  table)
    ;; Parentheses
    (modify-syntax-entry ?\( "()"  table)
    (modify-syntax-entry ?\) ")("  table)
    (modify-syntax-entry ?\{ "(}"  table)
    (modify-syntax-entry ?\} "){"  table)
    (modify-syntax-entry ?\[ "(]"  table)
    (modify-syntax-entry ?\] ")["  table)
    ;; Operators
    (modify-syntax-entry ?+ "."    table)
    (modify-syntax-entry ?- "."    table)
    (modify-syntax-entry ?* "."    table)
    (modify-syntax-entry ?/ "."    table)
    (modify-syntax-entry ?% "."    table)
    (modify-syntax-entry ?= "."    table)
    (modify-syntax-entry ?! "."    table)
    (modify-syntax-entry ?< "."    table)
    (modify-syntax-entry ?> "."    table)
    (modify-syntax-entry ?& "."    table)
    (modify-syntax-entry ?| "."    table)
    (modify-syntax-entry ?~ "."    table)
    (modify-syntax-entry ?^ "."    table)
    table)
  "Syntax table for `crisp-mode'.")

;; --- Font Lock Keywords ---------------------------------------------------

(defvar crisp--operator-face
  (if (facep 'font-lock-operator-face)
      'font-lock-operator-face
    'font-lock-keyword-face))

(defvar crisp--builtin-face
  (if (facep 'font-lock-builtin-face)
      'font-lock-builtin-face
    'font-lock-preprocessor-face))

(defvar crisp-font-lock-keywords
  `(;; Keywords
    (,(regexp-opt '("let" "const" "fn" "if" "else" "while" "for" "return"
                    "match" "where" "in" "use" "print" "say" "die" "warn"
                    "throw" "try" "catch" "finally" "break" "continue"
                    "class" "extends" "self" "super" "static" "new"
                    "true" "false" "null" "assert" "as")
                  'words)
     0 font-lock-keyword-face)

    ;; Built-in functions
    (,(regexp-opt '("map" "grep" "sort" "reduce" "sqrt" "pow" "abs"
                    "min" "max" "rand" "length" "trim" "split" "join"
                    "len" "push" "pop" "shift" "unshift" "filter"
                    "take" "zip" "type" "int" "float" "exit" "pid"
                    "sleep" "time" "timestamp" "system" "read_file"
                    "write_file" "file_exists" "readline" "read"
                    "input" "create_dir" "list_dir" "is_dir"
                    "regex_match" "regex_replace" "regex_split"
                    "regex_find_all" "regex_capture"
                    "to_json" "from_json" "to_json_pretty" "json_valid"
                    "md5" "sha1" "sha256" "sha512"
                    "base64_encode" "base64_decode" "random_bytes"
                    "tcp_connect" "tcp_listen" "tcp_accept"
                    "tcp_read" "tcp_write" "tcp_close"
                    "http_get" "http_post" "http_put" "http_delete" "http_patch"
                    "strftime" "strptime" "datetime" "datetime_utc"
                    "test" "assert_eq" "assert_ne" "assert_true"
                    "assert_false" "assert_throws")
                  'words)
     0 crisp--builtin-face)

    ;; Type names
    (,(regexp-opt '("int" "float" "string" "array" "hash" "bool" "null"
                    "object" "class" "function")
                  'words)
     0 font-lock-type-face)

    ;; Constants
    (,(regexp-opt '("PI" "E" "TAU") 'words)
     0 font-lock-constant-face)

    ;; String literals
    ("\"\\([^\"\\]\\|\\\\.\\)*\""
     0 font-lock-string-face)
    ("'\\([^'\\]\\|\\\\.\\)*'"
     0 font-lock-string-face)

    ;; Regex literals (m/.../, qr/.../)
    ("m/[^/\n]*/"
     0 font-lock-string-face)
    ("qr/[^/\n]*/"
     0 font-lock-string-face)

    ;; Substitution operator s/// with delimiters
    ("s/[^/\n]*/[^/\n]*/[gimsxe]*"
     0 font-lock-keyword-face)
    ("s#.*?#.*?#[gimsxe]*"
     0 font-lock-keyword-face)

    ;; Numeric literals
    ("\\_<-?[0-9][0-9_]*\\(\\.[0-9][0-9_]*\\)?\\_>"
     0 font-lock-constant-face)

    ;; Comments: #, //, /* */
    ("#.*$" 0 font-lock-comment-face)
    ("//.*$" 0 font-lock-comment-face)
    ("/\\*.*?\\*/" 0 font-lock-comment-face)

    ;; Doc comments: ///, //!
    ("///.*$" 0 font-lock-doc-face)
    ("//!.*$" 0 font-lock-doc-face)

    ;; Sigils
    ("\\$\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-variable-name-face)
    ("@\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-variable-name-face)
    ("%\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-variable-name-face)
    ("&\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-variable-name-face)

    ;; Function definition
    ("\\_<fn\\_>\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-function-name-face)

    ;; Class definition
    ("\\_<class\\_>\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)"
     1 font-lock-type-face)

    ;; Assignment
    ("\\_<\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*="
     1 font-lock-variable-name-face)

    ;; Method calls
    ("\\.\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*("
     1 font-lock-function-name-face)

    ;; Hash keys (with =>)
    ("{\\s-*\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*=>"
     1 font-lock-variable-name-face)

    ;; Lambda
    ("|\\([a-zA-Z_][a-zA-Z0-9_]*\\)|\\s-*=>"
     1 font-lock-variable-name-face)

    ;; Match patterns (match ... { pattern => })
    ("\\_<match\\_>.*?{\\s-*\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*=>"
     1 font-lock-constant-face)

    ;; Operators
    (,(regexp-opt '("+=" "-=" "*=" "/=" "%=" "**="
                    "==" "!=" "<=" ">=" "<=>" "=~" "!~"
                    "&&" "||" "<<" ">>" ".." "..." "**" "::") t)
     0 crisp--operator-face)

    ;; Contextual keywords
    ("\\_<new\\_>\\s-+\\([A-Z][a-zA-Z0-9_]*\\)"
     1 font-lock-type-face))

  "Font-lock keywords for `crisp-mode'.")

;; --- Templates -----------------------------------------------------------

(defun crisp--insert-template (template)
  "Insert a code template with proper indentation."
  (insert template)
  (indent-according-to-mode)
  (goto-char (point-min))
  (search-forward "|" nil t)
  (delete-char 1))

(defun crisp-insert-if-template ()
  "Insert an if statement template."
  (interactive)
  (crisp--insert-template "if | {\n    \n}"))

(defun crisp-insert-while-template ()
  "Insert a while loop template."
  (interactive)
  (crisp--insert-template "while | {\n    \n}"))

(defun crisp-insert-for-template ()
  "Insert a for loop template."
  (interactive)
  (crisp--insert-template "for | in | {\n    \n}"))

(defun crisp-insert-fn-template ()
  "Insert a function definition template."
  (interactive)
  (crisp--insert-template "fn |() {\n    \n}"))

(defun crisp-insert-class-template ()
  "Insert a class definition template."
  (interactive)
  (crisp--insert-template "class | {\n    fn new() {\n        \n    }\n}"))

(defun crisp-insert-try-template ()
  "Insert a try/catch/finally template."
  (interactive)
  (crisp--insert-template "try {\n    \n} catch | {\n    \n}"))

(defun crisp-insert-match-template ()
  "Insert a match statement template."
  (interactive)
  (crisp--insert-template "match | {\n    _ => { \n    }\n}"))

(defun crisp-insert-substitution-template ()
  "Insert a substitution operator template (s///)."
  (interactive)
  (insert "s/|/|/g")
  (search-backward "|")
  (delete-char 1))

;; --- Indentation ----------------------------------------------------------

(defun crisp-indent-line ()
  "Indent current line for CRISP mode."
  (interactive)
  (let ((indent (crisp--calculate-indentation)))
    (if (null indent)
        (indent-relative)
      (save-excursion
        (beginning-of-line)
        (delete-horizontal-space)
        (indent-to indent)))))

(defun crisp--looking-at-block-keyword-p ()
  "Return non-nil if current line starts with a block-introducing keyword."
  (save-excursion
    (beginning-of-line)
    (looking-at-p
     (concat "\\("
             "if\\|else\\|while\\|for\\|match\\|try\\|catch\\|"
             "finally\\|fn\\|class\\|let\\|const"
             "\\)\\>"))))

(defun crisp--prev-line-ends-with-fat-arrow-p ()
  "Return non-nil if the previous non-blank line ends with `=>'."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (end-of-line)
    (skip-chars-backward " \t")
    (and (> (point) (line-beginning-position))
         (char-equal (char-before) ?>)
         (> (point) (1+ (line-beginning-position)))
         (char-equal (char-before (1- (point))) ?\=))))

(defun crisp--prev-line-ends-with-sigil-p ()
  "Return non-nil if previous line ends with a sigil operator `=~` or `!~`."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
      (forward-line -1))
    (end-of-line)
    (skip-chars-backward " \t")
    (and (> (point) (1+ (line-beginning-position)))
         (char-equal (char-before) ?~)
         (memq (char-before (1- (point))) '(?= ?!)))))

(defun crisp--calculate-indentation ()
  "Calculate indentation for current line."
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        0
      (forward-line -1)
      (while (and (not (bobp)) (looking-at-p "^\\s-*$"))
        (forward-line -1))
      (let ((prev-indent (current-indentation))
            (prev-char
             (save-excursion
               (end-of-line)
               (skip-chars-backward " \t")
               (if (> (point) (line-beginning-position))
                   (char-before)
                 nil))))
        (forward-line 1)
        (let ((cur-indent
               (cond
                ((and prev-char (memq prev-char '(?\{ ?\[ ?\()))
                 (+ prev-indent crisp-indent-offset))
                ((crisp--looking-at-block-keyword-p)
                 (+ prev-indent crisp-indent-offset))
                ((crisp--prev-line-ends-with-fat-arrow-p)
                 (+ prev-indent crisp-indent-offset))
                ((crisp--prev-line-ends-with-sigil-p)
                 (+ prev-indent crisp-indent-offset))
                ((looking-at-p "^\\s-*[][}]")
                 (max 0 (- prev-indent crisp-indent-offset)))
                ((looking-at-p "^\\s-*\\(else\\|catch\\|finally\\)\\>")
                 (max 0 (- prev-indent crisp-indent-offset)))
                (t prev-indent))))
          (max cur-indent 0))))))

(defun crisp--in-string-or-comment-p ()
  (nth 8 (syntax-ppss)))

;; --- Electric Enter (auto-indent) -----------------------------------------

(defun crisp-electric-newline ()
  "Insert a newline and indent it properly."
  (interactive)
  (newline)
  ;; Force indentation even on empty lines
  (when (and (not (crisp--in-string-or-comment-p))
             (not (eq (char-before) ?\\)))
    (indent-according-to-mode)))

;; --- Mode Definition -----------------------------------------------------

;;;###autoload
(define-derived-mode crisp-mode prog-mode "CRISP"
  "Major mode for editing CRISP source code.

CRISP is a modern scripting language inspired by Perl and implemented in Rust.

Key bindings:
\\<crisp-mode-map>
\\[crisp-indent-line]\tIndent current line.

Templates:
C-c i f  if statement
C-c i w  while loop
C-c i F  for loop
C-c i n  function
C-c i c  class
C-c i t  try/catch
C-c i m  match statement
C-c i s  substitution operator (s///)"

  ;; --- Basic setup ---
  (setq-local font-lock-defaults '(crisp-font-lock-keywords nil nil))
  (setq-local indent-line-function #'crisp-indent-line)
  (setq-local comment-start "#")
  (setq-local comment-start-skip "\\(#\\|//\\)+\\s-*")
  (setq-local comment-end "")

  ;; --- Support multiple comment styles ---
  (setq-local comment-use-syntax t)
  (setq-local comment-add 1)

  ;; --- Electric Indent (auto-indent on Enter) ---
  (electric-indent-local-mode 1)
  (add-to-list 'electric-indent-chars ?\n)

  ;; --- Use custom electric-newline for Enter ---
  (local-set-key (kbd "RET") #'crisp-electric-newline)

  ;; --- Templates ---
  (local-set-key (kbd "C-c i f") #'crisp-insert-if-template)
  (local-set-key (kbd "C-c i w") #'crisp-insert-while-template)
  (local-set-key (kbd "C-c i F") #'crisp-insert-for-template)
  (local-set-key (kbd "C-c i n") #'crisp-insert-fn-template)
  (local-set-key (kbd "C-c i c") #'crisp-insert-class-template)
  (local-set-key (kbd "C-c i t") #'crisp-insert-try-template)
  (local-set-key (kbd "C-c i m") #'crisp-insert-match-template)
  (local-set-key (kbd "C-c i s") #'crisp-insert-substitution-template)

  ;; --- Indentation settings ---
  (setq-local tab-width crisp-indent-offset)
  (setq-local indent-tabs-mode nil)

  ;; --- Prettify symbols ---
  (when (fboundp 'prettify-symbols-mode)
    (prettify-symbols-mode +1))

  ;; --- Imenu ---
  (setq-local imenu-generic-expression
              `(("Functions" "\\_<fn\\_>\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1)
                ("Classes" "\\_<class\\_>\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1)))

  ;; --- Tree-sitter support (optional) ---
  (when (and crisp-use-tree-sitter
             (fboundp 'treesit-available-p)
             (treesit-available-p)
             (fboundp 'treesit-ready-p)
             (treesit-ready-p 'crisp t))
    (crisp--setup-treesitter)))

;; --- Tree-Sitter Setup ---------------------------------------------------

(defun crisp--setup-treesitter ()
  "Setup tree-sitter for CRISP mode."
  (when (and (fboundp 'treesit-available-p)
             (treesit-available-p)
             (fboundp 'treesit-ready-p)
             (treesit-ready-p 'crisp t))
    (when (and (fboundp 'treesit-font-lock-rules)
               (fboundp 'treesit-major-mode-setup))
      (setq-local treesit-font-lock-settings
                  (treesit-font-lock-rules
                   :feature 'comment
                   '((comment) @font-lock-comment-face)
                   :feature 'doc
                   '((doc_comment) @font-lock-doc-face)
                   :feature 'string
                   '((string) @font-lock-string-face)
                   :feature 'regex
                   '((regex) @font-lock-string-face)
                   :feature 'number
                   '((number) @font-lock-constant-face)
                   :feature 'keyword
                   '((keyword) @font-lock-keyword-face)
                   :feature 'function
                   '((function_name) @font-lock-function-name-face)
                   :feature 'type
                   '((class_name) @font-lock-type-face)
                   :feature 'variable
                   '((variable_name) @font-lock-variable-name-face)
                   :feature 'operator
                   '((operator) @font-lock-operator-face)
                   :feature 'sigil
                   '((sigil) @font-lock-variable-name-face)))
      (setq-local treesit-font-lock-feature-list
                  '((comment doc string regex number)
                    (keyword function type variable operator sigil)))
      (treesit-major-mode-setup))))

;; --- File Associations ---------------------------------------------------

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.csp\\'" . crisp-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.crisp\\'" . crisp-mode))

;; --- Interactive Commands ------------------------------------------------

(defun crisp-insert-sigil ()
  "Insert a sigil ($, @, %, or &) at point."
  (interactive)
  (let ((sigil (read-char-choice "Sigil: ($ @ % &) " '(?$ ?@ ?% ?&))))
    (insert (char-to-string sigil))))

;;;###autoload
(defun crisp-eval-region (beg end)
  "Evaluate selected region as CRISP code."
  (interactive "r")
  (message "Evaluating CRISP code...")
  (shell-command-on-region beg end "crisp -e -" nil t))

(defun crisp-comment-region ()
  "Comment the region using CRISP comment style (#)."
  (interactive)
  (comment-region (region-beginning) (region-end)))

(defun crisp-uncomment-region ()
  "Uncomment the region using CRISP comment style (#)."
  (interactive)
  (uncomment-region (region-beginning) (region-end)))

(defvar crisp-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'crisp-eval-region)
    (define-key map (kbd "C-c $")   #'crisp-insert-sigil)
    (define-key map (kbd "C-c ;")   #'crisp-comment-region)
    (define-key map (kbd "C-c C-;") #'crisp-uncomment-region)
    map)
  "Keymap for `crisp-mode'.")

(provide 'crisp-mode)

;;; crisp-mode.el ends here
