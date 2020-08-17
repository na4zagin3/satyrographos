open Core
open Satyrographos

module Process = Shexp_process
module P = Process

module StringMap = Map.Make(String)

let library_dir prefix (buildscript: BuildScript.m) =
  let libdir = Filename.concat prefix "share/satysfi" in
  Filename.concat libdir (BuildScript.get_name buildscript)

let read_module ~outf ~verbose ~build_module ~buildscript_path =
  let src_dir = Filename.dirname buildscript_path in
  let p = BuildScript.read_module ~src_dir build_module in
  if verbose
  then begin Format.fprintf outf "Read library:@.";
    [%sexp_of: Library.t] p |> Sexp.pp_hum outf;
    Format.fprintf outf "@."
  end;
  (src_dir, p)

let test_satysfi_option options =
  let open P in
  let open P.Infix in
  run_bool ~false_v:[2] "satysfi" (options @ ["--version"])
  |> capture [Stdout]
  >>| fst

let assert_satysfi_option ~message options =
  let open P in
  test_satysfi_option options
  |> map ~f:(function
    | true -> ()
    | false -> failwith message)

let assert_satysfi_option_C dir =
  assert_satysfi_option ~message:"satysfi.0.0.3+dev2019.02.27 and newer is required in order to build library docs."
    ["-C"; dir]

let with_env ~outf ~setup c =
  let open P in
  let open P.Infix in
  let c satysfi_runtime =
    return (Format.fprintf outf "Setting up SATySFi env at %s @." satysfi_runtime;) >>
    let satysfi_dist = Filename.concat satysfi_runtime "dist" in
    return (Library.mark_managed_dir satysfi_dist;) >>
    return (setup ~satysfi_dist) >>
    c satysfi_runtime
  in
  with_temp_dir ~prefix:"Satyrographos" ~suffix:"with_env" c

let run_satysfi_command ~satysfi_runtime args =
  let open P.Infix in
  assert_satysfi_option_C satysfi_runtime
  >> P.run "satysfi" (["-C"; satysfi_runtime] @ args)

let run_satysfi ~satysfi_runtime args =
  let command =
    run_satysfi_command ~satysfi_runtime args in
  ProcessUtil.redirect_to_stdout ~prefix:"satysfi" command

