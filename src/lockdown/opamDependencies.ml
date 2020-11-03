open Core

open LockdownFile
module P = Shexp_process

let opam_installed_transitive_dependencies_com ~verbose:_ packages =
  let open P.Infix in
  let cmd =
    P.run "opam" [
      "list";
      "-i";
      "--color=never";
      "--columns";
      "name,installed-version";
      "--separator=,";
      "--recursive";
      "--required-by"; String.concat ~sep:"," packages]
    |> P.capture_unit [P.Std_io.Stdout]
    >>| String.split_lines
    >>| List.filter ~f:(fun l -> String.is_prefix ~prefix:"#" l |> not)
    >>| List.filter_map ~f:(fun l ->
        match String.split_on_chars ~on:[','] l with
        | [name; version] -> Some {
            name = String.strip name;
            version = String.strip version;
          }
        | [""] | [] -> None
        | _ ->
          failwithf
            "BUG: Unrecognizable package information from OPAM: %S"
            l
            ()
      )
  in
  P.echo "Gathering OPAM package information..."
  >> cmd

let get_opam_dependencies ~verbose packages =
  let packages =
    opam_installed_transitive_dependencies_com ~verbose packages
    |> P.eval
  in
  { packages; }

let restore_opam_dependencies_com ~verbose (dependencies : opam_dependencies) =
  let packages =
    dependencies.packages
    |> List.map ~f:(fun {name; version;} ->
        sprintf "%s.%s" name version)
  in
  [
    ["install"; "--yes";];
    if verbose
    then ["--verbose";]
    else [];
    packages;
  ]
  |> List.concat
  |> P.run "opam"

let restore_opam_dependencies ~verbose (dependencies : opam_dependencies) =
  restore_opam_dependencies_com ~verbose dependencies
  |> P.eval
