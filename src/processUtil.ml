open Core

module P = Shexp_process

let redirect_to_stdout ?(prefix="") ?(prefix_out="out>") ?(prefix_err="err>") com =
  let open P in
  let put_prefix x = if String.is_empty prefix then x else prefix ^ " " ^ x in
  let prefix_out = put_prefix prefix_out in
  let prefix_err = put_prefix prefix_err in
  let iter_lines_prefix ?where prefix =
    iter_lines (fun l -> if String.is_empty l then echo ?where prefix else echo ?where (prefix ^ " " ^ l)) in
  epipe (pipe com (iter_lines_prefix prefix_out)) (iter_lines_prefix ~where:Std_io.Stderr prefix_err)

let%expect_test "redirect_to_stdout: stdout" =
  let open P in
  let open P.Infix in
  let com =
    echo ~where:P.Std_io.Stdout "output to stdout 1"
    >> echo ~where:P.Std_io.Stdout "output to stdout 2"
    >> echo ~where:P.Std_io.Stdout "output to stdout 3" in
  let wrapped = redirect_to_stdout com in
  P.eval wrapped;
  [%expect{|
    out> output to stdout 1
    out> output to stdout 2
    out> output to stdout 3 |}]

let%expect_test "redirect_to_stdout: stderr" =
  let open P in
  let open P.Infix in
  let com =
    echo ~where:P.Std_io.Stderr "output to stdout 1"
    >> echo ~where:P.Std_io.Stderr "output to stdout 2"
    >> echo ~where:P.Std_io.Stderr "output to stdout 3" in
  let wrapped = redirect_to_stdout com in
  P.eval wrapped;
  [%expect{|
    err> output to stdout 1
    err> output to stdout 2
    err> output to stdout 3 |}]

let%expect_test "redirect_to_stdout: with prefix" =
  let open P in
  let open P.Infix in
  let com =
    echo ~where:P.Std_io.Stdout "output to stdout 1"
    >> echo ~where:P.Std_io.Stdout "output to stdout 2" in
  let wrapped = redirect_to_stdout ~prefix:"com" com in
  P.eval wrapped;
  [%expect{|
    com out> output to stdout 1
    com out> output to stdout 2 |}]
