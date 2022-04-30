open Core
open Satyrographos

module Process = Shexp_process
module P = Process
module OW = Satyrographos.OpamWrapper

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

let with_env ~outf ~(project_env : Satyrographos.Environment.project_env option) ~setup c =
  let open P in
  let open P.Infix in
  match project_env with
  | None ->
    let c satysfi_runtime =
      return (Format.fprintf outf "Setting up SATySFi env at %s @." satysfi_runtime;) >>
      let satysfi_dist = Filename.concat satysfi_runtime "dist" in
      return (Library.mark_managed_dir satysfi_dist;) >>
      return (setup ~satysfi_dist) >>
      c satysfi_runtime
    in
    with_temp_dir ~prefix:"Satyrographos" ~suffix:"with_env" c
  | Some project_env ->
    let open Satyrographos.Environment in
    get_satysfi_runtime_dir project_env
    |> c

let run_satysfi_command ~satysfi_runtime args =
  let open P.Infix in
  Satyrographos_satysfi.Version.get_current_version_cmd
  >>= function
  | None ->
    P.run "satysfi" (["-C"; satysfi_runtime; "--no-default-config"] @ args)
  | Some v when Satyrographos_satysfi.Version.has_option_no_default_config v ->
    P.run "satysfi" (["-C"; satysfi_runtime; "--no-default-config"] @ args)
  | Some v when Satyrographos_satysfi.Version.has_option_C v ->
    P.run "satysfi" (["-C"; satysfi_runtime] @ args)
  | _ ->
    assert_satysfi_option_C satysfi_runtime
    >> P.run "satysfi" (["-C"; satysfi_runtime] @ args)

let satysfi_command ~outf ~system_font_prefix ~autogen_libraries ~libraries ~verbose ~(project_env : Satyrographos.Environment.project_env option) ~env args =
  let persistent_autogen =
    (* TODO Enable lockdown for freestanding satysfi subcommand invocations *)
    project_env
    |> Option.bind ~f:(fun project_env ->
        Lockdown.load_lockdown_file ~buildscript_path:project_env.buildscript_path
      )
    |> Option.value_map ~default:[] ~f:(fun (lockdown : Satyrographos_lockdown.LockdownFile.t) ->
        lockdown.autogen
      )
  in
  let setup ~satysfi_dist =
    Install.install
      satysfi_dist
      ~outf
      ~system_font_prefix
      ~autogen_libraries
      ~libraries
      ~verbose
      ~copy:false
      ~persistent_autogen
      ~env
      ()
  in
  let commands satysfi_runtime =
    let open P in
    let open P.Infix in
    echo "Running SATySFi..."
    >> echo "=================="
    >> assert_satysfi_option_C satysfi_runtime
    >> P.run_exit_code "satysfi" (["-C"; satysfi_runtime] @ args)
  in
  with_env ~outf ~project_env ~setup commands
