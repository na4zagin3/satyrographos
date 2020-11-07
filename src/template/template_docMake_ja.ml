let name = "[experimental]doc-make@ja"

let local_satyh_template =
"local.satyh",
{|% プロジェクト用函数・コマンド定義用ファイル
@require: code
@require: math


let-block ctx +frame content =
  let pads = (10pt, 10pt, 10pt, 10pt) in
  let decoset = VDecoSet.simple-frame-stroke 1pt (Color.gray 0.75) in
    block-frame-breakable ctx pads decoset (fun ctx -> read-block ctx content)

let-block ctx +display-boxes content code =
  read-block (ctx |> set-paragraph-margin 12pt 0pt) '<+frame(content);>
    +++ read-block (ctx |> set-paragraph-margin 0pt 12pt) '<+code(code);>

% 数式コマンドの定義
let-math \factorial x =
  ${#x \mathpunct{\mathrm-token!(`!`)}}
|}

let main_saty_template =
"main.saty",
{|% 文書ファイル

% 文書クラスパッケージ
@require: stdjabook

% SATySFi標準パッケージ
@require: annot
@require: code
@require: math
@require: itemize

% Satyrographosパッケージ
@require: fss/fss
@require: fss/fonts
@require: fss/style

% プロジェクト内パッケージ
@import: local


document (|
  title = {表題};
  author = {名前};
  show-title = true;
  show-toc = false;
|) '<
  +p {
    このテンプレートは\SATySFi; 0.0.5用であり、
    \SATySFi;はいまだ開発段階にあるので、
    \font-style[bold]{破壊的変更に注意すべし}。
  }
  +p {
    オンライン
    \listing{
      * \href(`https://github.com/gfngfn/SATySFi/blob/master/demo/demo.saty`){`demo.saty`} is a brief introduction to \SATySFi;.
      * Please join \href(`https://github.com/gfngfn/SATySFi/wiki/SATySFi-Wiki#satsysfi-slack`){\emph{SATySFi Slack}}!
      * \SATySFi;本体に付属している\href(`https://github.com/na4zagin3/SATySFi/blob/master/demo/demo.saty`){デモファイル}も参考にすべし。
    }%
  }
  +p {
    `+p { ... }`は段落を表す。
    細かく言えば、`+p`は行内テキスト`{ ... }`を引数として取る段落コマンドである。
  }
  +p {
    行内数式は数式オブジェクト`${ ... }`で表される。例：${x^2 - x + 1}。
  }
  +p {
    基本的な数式コマンドは\LaTeX;のものに似ている。例：${f: A \to \mathbb{R}}。
  }
  +p {
    数式コマンドや\LaTeX;のコマンドとは異なり、行内コマンドや段落コマンドは終端文字`;`を要する。但し、最後の引数が行内テキスト`{ ... }`か段落テキスト`< ... >`である場合を除く。例：\emph{emph}、\code(`code`);。
  }
  +p({
    テキストコマンドの各引数は括弧で囲まれる。
    例：\emph{abc}、\emph({abc});。
  });
  +p {
    別行立て数式は`\eqn`に数式オブジェクトを適用することで得られる。例：
    \eqn(${
      \int_{M} d\alpha = \int_{\partial M}\alpha.
    });%
    同様に別行立てコード例は`\d-code`で得られる。
    \d-code(```
    \eqn(${
      \int_{M} d\alpha = \int_{\partial M}\alpha
    });
    ```);%
  }
  +p {
    `\math-list`コマンドは数式オブジェクトの排列を一つ引数として取る。
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
    `\align`コマンドは数式オブジェクトの排列の排列を一つ引数として取る。
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
  +section{節} <
    +p {
      節は
      \code(`+section{節題} < 段落コマンド... >`);.
      の形式で表される。
    }
    +subsection{項} <
      +p {
        `+subsection`コマンドもある。
      }
    >
  >
  +section{パッケージ} <
    +p {
      `@require`指令を用いることで、\SATySFi;標準パッケージやSatyrographosパッケージを読み込むことができる。
    }
    +code (`
      @require: math
    `);
    +p {
      `@import`指令は現在のファイルからの相対パスに存在するパッケージを読み込む。
    }
    +code (`
      % この指令は local.satyh ファイルを読み込む
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

let readme_template =
"README.md",
{|# @@library@@

素敵な文書

## 処理方法

`satyrographos build`コマンドを走らせること。
|}

let files = [
    main_saty_template;
    local_satyh_template;
    satyristes_template;
    Template_docMake_en.gitignore_template;
    Template_docMake_en.makefile_template;
    readme_template;
  ]

let template =
  name, ("Document with Makefile (ja)", files)
