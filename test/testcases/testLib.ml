module StdList = List

open Shexp_process
open Shexp_process.Infix

let exec_log_file_path temp_dir = FilePath.concat temp_dir "commands.log"

let repeat_string n s : string =
  StdList.init n (fun _ -> s) |> StdList.fold_left (^) ""

(** Remove nondeterministic part from automatically generated temp dir names *)
let replace_tempdirs =
  let re =
    let open Re in
    seq [
      str {|/tmp/Satyrographos|};
      repn xdigit 6 (Some 6);
      rep wordc |> group;
    ] |> compile in
  let f g = "@@" ^ Re.Group.get g 1 ^ "@@" in
  (fun s -> Re.replace re ~all:true ~f s)

let censor_tempdirs =
  iter_lines (fun s -> replace_tempdirs s |> echo)

let censor replacements =
  iter_lines (fun s -> Stringext.replace_all_assoc s replacements |> echo)

let with_formatter ?(where=Std_io.Stdout) f =
  let buf = Buffer.create 100 in
  let fmt = Format.make_formatter (Buffer.add_substring buf) ignore in
  let v = f fmt in
  echo ~where ~n:() (Buffer.contents buf)
  >> return v

let echo_line =
  echo "------------------------------------------------------------"

let dump_dir dir : unit t =
  with_temp_dir ~prefix:"Satyrographos" ~suffix:"dump_dir" (fun empty_dir ->
    (run "find" [dir] |- run "sort" [])
    >> echo_line
    >> run_exit_code "diff" ["-Nr"; empty_dir; dir] >>| (fun _ -> ())
    |- censor [ empty_dir, "@@empty_dir@@"; ]
  )

let stacktrace = false

let test_install ?(replacements=[]) setup f : unit t =
  let test dest_dir temp_dir =
    let opam_prefix = Unix.open_process_in "opam var prefix" |> input_line (* Assume a path does not contain line breaks*) in
    let replacements =
      [ opam_prefix, "@@opam_prefix@@";
        dest_dir, "@@dest_dir@@";
        temp_dir, "@@temp_dir@@";
        Unix.getenv "HOME", "@@home_dir@@";
      ] @ replacements in
    echo "Installing packages"
    >> echo_line
    >> setup ~dest_dir ~temp_dir
    >>= (fun setup_result ->
      try
        with_formatter (fun outf -> f setup_result ~dest_dir ~temp_dir ~outf; Format.fprintf outf "@?")
      with e ->
        echo "Exception:"
        >> echo (Printexc.to_string e)
        >> if stacktrace
           then echo "Stack trace:"
             >> echo (Printexc.get_backtrace())
           else return ()
      )
    >> echo_line
    >> dump_dir dest_dir
    >>= (fun () ->
      let log_file = exec_log_file_path temp_dir in
      if FileUtil.(test Is_file log_file)
      then echo_line >> stdin_from log_file (iter_lines echo)
      else return ())
    |- censor replacements
    |- censor_tempdirs in
  (with_temp_dir ~prefix:"Satyrographos" ~suffix:"test_dest"
    (fun dest_dir ->
      with_temp_dir ~prefix:"Satyrographos" ~suffix:"test_temp" (test dest_dir)))

let read_env ?repo:_ ?opam_reg ?dist_library_dir () =
  Satyrographos.Environment.{
    repo = None;
    opam_reg = begin match opam_reg with
      | Some opam_reg -> Satyrographos.OpamSatysfiRegistry.read opam_reg
      | None -> None end;
    dist_library_dir;
  }
