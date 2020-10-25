let name = "doc-make"

let local_satyh_template =
"local.satyh",
{|% This is a file for local function/command definitions
@require: code


let-block ctx +frame content =
  let pads = (10pt, 10pt, 10pt, 10pt) in
  let decoset = VDecoSet.simple-frame-stroke 1pt (Color.gray 0.75) in
    block-frame-breakable ctx pads decoset (fun ctx -> read-block ctx content)

let-block ctx +display-boxes content code =
  read-block (ctx |> set-paragraph-margin 12pt 0pt) '<+frame(content);>
    +++ read-block (ctx |> set-paragraph-margin 0pt 12pt) '<+code(code);>
|}

let main_saty_template =
"main.saty",
{|% This is the document file

% Require stdjabook class package
@require: stdjabook

% Here are standard packages
@require: annot
@require: code
@require: math
@require: itemize

% Here are third-party packages
@require: fss/fss
@require: fss/fonts
@require: fss/style

% Here is a local package
@import: ./local


document (|
  title = {Test Document};
  author = {Your Name};
  show-title = true;
  show-toc = true;
|) '<
  +p {
    This template is for \SATySFi; 0.0.5.
    As \SATySFi; is not yet mature,
    please be warned that \font-style[italic]{you may experience some breaking changes}.
  }
  +p {
    Please join \href(`https://github.com/gfngfn/SATySFi/wiki/SATySFi-Wiki#satsysfi-slack`){\emph{SATySFi Slack}}!
  }
  +p {
    `+p` block command represents a paragraph with indentation.
  }
  +pn {
    On the other hand, `+pn` block command represents a paragraph without indentation.
  }
  +p {
    Block commands `+p` and `+pn` take a inline text `{ ... }` object.
  }
  +p {
    An inline equation is represented by `${ ... }`. E.g., ${x^2 - x + 1}.
  }
  +p {
    Basic math commands resemble those in \LaTeX;. E.g., ${f: A \to \mathbb{R}}.
  }
  +p {
    Unlike math commands or \LaTeX; commands, a text command needs argument terminator “`;`” if the last argument is neither `{ ... }` (i.e., an inline text) or `< ... >` (i.e., a block text): \emph{emph} vs. \code(`code`);.
  }
  +p({
    Each text command takes parenthesized arguments or block/inline texts.
    E.g., \emph{abc} vs. \emph({abc});.
  });
  +p {
    Block commands start with `+`; inline and math commands starts with `\`.
  }
  +p {
    `math` package provides enormous commands for equations.
  }
  +math(${
    \int_{M} d\alpha = \int_{\partial M}\alpha
  });
  +section{Sections} <
    +p {
      A new section is created by
      \code(`+section{Section title} < block commands... >`);.
    }
    +subsection{Subsection} <
      +p {
        There's `+subsection` command too.
      }
    >
  >
  +section{Packages} <
    +p {
      You can import standard/third-party packages with `@require` directive:
    }
    +code (`
      @require: math
    `);
    +p {
      `@import` directive will import a package from the relative path to this file.
    }
    +code (`
      % This directive imports local.satyh file
      @import: ./local
    `);
  >
>
|}

let satyristes_template =
"Satyristes",
{|(lang "0.0.3")

(doc
  (name  "main")
  (build ((make)))
  (dependencies
   (;; Standard library
    (dist ())
    ;; Third-party library
    (fss ())
    )))
|}

let gitignore_template =
".gitignore",
{|# OMake
*.omc
.omakedb.lock

# Satyristes
*.deps

# SATySFi
*.satysfi-aux

# Generated files
main.pdf
|}

let makefile_template =
  "Makefile",
  {|.PHONY: all

all: doc

# SATySFi/Satyrographos rules
%.pdf: %.saty
	satyrographos satysfi -- -o $@ $<
%.pdf.deps: %.saty
	satyrographos util deps -r -p --depfile $@ --mode pdf -o "$(basename $@)" $<


# User rules
doc: main.pdf
-include main.pdf.deps
|}

let readme_template =
"README.md",
{|# @@library@@

A great document.

## How to compile?

Run `satyrographos build`.
|}

let files = [
    main_saty_template;
    local_satyh_template;
    satyristes_template;
    gitignore_template;
    makefile_template;
    readme_template;
  ]
