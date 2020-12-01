(*
   SPDX-License-Identifier: CC0-1.0
*)

let name = "[experimental]doc-make@en"

let local_satyh_template =
"local.satyh",
{|% This is a file for local function/command definitions
@require: code
@require: math


let-block ctx +frame content =
  let pads = (10pt, 10pt, 10pt, 10pt) in
  let decoset = VDecoSet.simple-frame-stroke 1pt (Color.gray 0.75) in
    block-frame-breakable ctx pads decoset (fun ctx -> read-block ctx content)

let-block ctx +display-boxes content code =
  read-block (ctx |> set-paragraph-margin 12pt 0pt) '<+frame(content);>
    +++ read-block (ctx |> set-paragraph-margin 0pt 12pt) '<+code(code);>

% Define a math command
let-math \factorial x =
  ${#x \mathpunct{\mathrm-token!(`!`)}}
|}

let main_saty_template =
"main.saty",
{|% This is the document file

% Class package
@require: stdjabook

% Standard packages
@require: annot
@require: code
@require: math
@require: itemize

% Third-party packages
@require: fss/fss
@require: fss/fonts
@require: fss/style

% Local package
@import: local


document (|
  title = {Test Document};
  author = {Your Name};
  show-title = true;
  show-toc = false;
|) '<
  +p {
    This template is for \SATySFi; 0.0.5.
    As \SATySFi; is not yet murture,
    please be warned that \font-style[italic]{you may experience some breaking changes}.
  }
  +p {
    There are online resources, so Please check out!
    \listing{
      * \href(`https://github.com/gfngfn/SATySFi/blob/master/demo/demo.saty`){`demo.saty`} is a brief introduction to \SATySFi;.
      * Please join \href(`https://github.com/gfngfn/SATySFi/wiki/SATySFi-Wiki#satsysfi-slack`){\emph{SATySFi Slack}}!
    }%
  }
  +p {
    As you see, `+p { ... }` represents a paragraph.
    Technically speaking, `+p` is a block command applied to an inline text object `{ ... }`.
  }
  +p {
    An inline equation is represented by a math object `${ ... }`. E.g., ${x^2 - x + 1}.
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
    You can get a displayed equation by applying `\eqn` command to a math object. E.g.,
    \eqn(${
      \int_{M} d\alpha = \int_{\partial M}\alpha.
    });%
    Similarly, you can get a code example with `\d-code` command.
    \d-code(```
    \eqn(${
      \int_{M} d\alpha = \int_{\partial M}\alpha
    });
    ```);%
  }
  +p {
    `\math-list` takes a list of math objects.
    \math-list[
      ${\delta_{ij} = \cases![
        (${1}, {${i = j}});
        (${0}, {otherwise});
      ]};
      ${\epsilon_{a_{1}a_{2}\cdots a_{n}} =
        \lower{\prod}{1\leq i\leq j\leq n}
          \mathop{\mathrm{sgn}}\paren{a_{j} - a_{i}}
      };
    ];%
    `\align` takes a list of lists of math objects.
    \align[
      [ ${\pi};
        ${=\paren{
          \frac{2\sqrt{2}}{99^{2}}\upper{\lower{\sum}{n=0}}{\infty}
            \frac{
              \factorial{\paren{4n}}
              \paren{1103 + 26390n}
            }{
              \paren{4^{n} 99^{n} \factorial{n}}^{4}
            }
          }^{-1}
        };
      ];
      [ ${};
        ${=\paren{
          \int_{-\infty}^{\infty}
          e^{
            -x^2
          }
          \mathrm{d}x
        }^{ 2 }
        };
      ];
    ];%
  }
  +section{Sections} <
    +p {
      A new section is created by
      \code(`+section{Section title} < block commands... >`);.
    }
    +subsection{Subsection} <
      +p {
        There’s `+subsection` command too.
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
    dist
    ;; Third-party library
    fss
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

let template =
  name, ("Document with Makefile (en)", files)
