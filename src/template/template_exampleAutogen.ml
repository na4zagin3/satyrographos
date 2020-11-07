let main_saty_template =
  "main.saty", {|
@require: stdjabook
@require: math
@require: itemize
@require: $fonts
@require: $libraries
@require: $today

let abc = {ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz,.\;.!?}
let lorem = {Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.}
let math-example = {${\abs{\mathrm{Orb}_G\(x\)} \cdot \abs{\mathrm{Stab}_G\(x\)} = \abs{G}}}


let-inline \show-string s = embed-string s
let-inline \show-float s = embed-string (show-float s)
let-inline \show-int i = embed-string (arabic i)
let-inline ctx \with-math-font font it =
  let ctx = ctx
    |> set-math-font font#name in
  read-inline ctx it
let-inline ctx \with-text-font font it =
  let ctx = ctx
    |> set-font Latin (font#name, 1., 0.)
    |> set-font OtherScript (font#name, 1., 0.) in
  read-inline ctx it
let-inline \identity x = x
let-inline \optionally-show pre x post = match x with
  | None -> {}
  | Some x -> {\identity(pre);\show-string(x);\identity(post);}
let-inline \font-location font =
  match font#font-location with
  | Single src ->
    {Single \{src = \show-string(src#src);\;
	 \optionally-show({orig-location = })(src#orig-location)({\; });\}}
  | Collection src ->
    {Collection \{src = \show-string(src#src);\;
		index = \show-int(src#index);\;
    	\optionally-show({orig-location =\ })(src#orig-location)({\; });\}}

let show-math-font-block-text ctx font =
  '<
    +subsection{\show-string(font#name);} <
      +pn {
        Name: \show-string(font#name);
      }
      +pn {
        Library: \show-string(font#library-name);
      }
      +pn {
        Location: \font-location(font);
      }
      +p {
        \with-math-font(font)(math-example);
      }
    >
  >

let show-text-font-block-text ctx font =
  '<
    +subsection{\show-string(font#name);} <
      +pn {
        Name: \show-string(font#name);
      }
      +pn {
        Library: \show-string(font#library-name);
      }
      +pn {
        Location: \font-location(font);
      }
      +pn {
        \with-text-font(font)(abc);
      }
      +p {
        \with-text-font(font)(lorem);
      }
    >
  >

let is-text-font font = match font#font-type with
  | TextFont -> true
  | _ -> false

let is-math-font font = match font#font-type with
  | MathFont -> true
  | _ -> false

let-block ctx +show-text-fonts fonts =
  List.filter is-text-font fonts
  |> List.map (show-text-font-block-text ctx)
  |> List.map (read-block ctx)
  |> List.fold-left (+++) block-nil

let-block ctx +show-math-fonts fonts =
  List.filter is-math-font fonts
  |> List.map (show-math-font-block-text ctx)
  |> List.map (read-block ctx)
  |> List.fold-left (+++) block-nil

let show-library-block-text ctx library =
  '<
    +subsection{\show-string(library#name);} <
      +pn {
        Name: \show-string(library#name);
      }
      +pn {
        Version: \show-string(library#version);
      }
    >
  >

let-block ctx +show-libraries libraries =
  libraries
  |> List.map (show-library-block-text ctx)
  |> List.map (read-block ctx)
  |> List.fold-left (+++) block-nil

in

document (|
  title = {};
  author = {};
  show-title = false;
  show-toc = false;
|) '<
  +p {
    Built at \code(Today.datetime); (\code(Today.tzname);).
  }
  +section{Packages}<
    +show-libraries(Libraries.list);
  >
  +section{Math Fonts}<
    +show-math-fonts(Fonts.list);
  >
  +section{Text Fonts}<
    +show-text-fonts(Fonts.list);
  >
>
|}

let satyristes_template =
"Satyristes",
{|(lang "0.0.3")

(doc
  (name  "main")
  (build ((satysfi main.saty -o main.pdf)))
  (autogen ($fonts $libraries $today))
  (dependencies
   (;; Standard library
    dist
    ;; Third-party library
    fss
    )))
|}

let readme_template =
"README.md",
{|# @@library@@

An example with autogen libraries

## How to compile?

Run `satyrographos build`.
|}

let files = [
  main_saty_template;
  satyristes_template;
  Template_docMake_en.gitignore_template;
  readme_template;
]

let template =
  "[experimental]example-autogen", ("Example with autogen libraries", files)
