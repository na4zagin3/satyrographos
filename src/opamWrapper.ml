open Core

module P = Shexp_process

module OpamRepositoryName = struct
  include OpamRepositoryName

  let compare a b =
    String.compare
      (OpamRepositoryName.to_string a)
      (OpamRepositoryName.to_string b)

  let equal a b =
    String.equal
      (OpamRepositoryName.to_string a)
      (OpamRepositoryName.to_string b)

end

let opam_package_name_satysfi = OpamPackage.Name.(of_string "satysfi")

let get_satysfi_opam_registry switch =
  let get_reg_from_root switch =
    let root = OpamStateConfig.(!r.root_dir) in
    Format.(OpamFilename.Dir.to_string root |> printf !"root: %s\n");
    let switch_config_file = OpamPath.Switch.switch_config root switch in
    Format.(OpamFile.to_string switch_config_file |> printf !"switch_config_file: %s\n");
    let switch_config = OpamFile.Switch_config.read switch_config_file in
    Format.(OpamFile.Switch_config.write_to_string switch_config |> printf !"switch_config: %s\n");
    OpamPath.Switch.share root switch switch_config opam_package_name_satysfi
  in
  OpamGlobalState.with_ `Lock_none @@ fun gt ->
  let global_switch = OpamFile.Config.switch gt.config in
  match switch, global_switch with
  | Some switch, _ ->
    Some (get_reg_from_root switch)
  | None, Some switch ->
    Some (get_reg_from_root switch)
  | None, None ->
    None

let get_satysfi_opam_registry_exc switch =
  get_satysfi_opam_registry switch
  |> Option.value_exn ~message:"Failed to get opam directory."

let dune_cache_envs = [
  "DUNE_CACHE", "enabled";
  "DUNE_CACHE_TRANSPORT", "direct";
]

let with_dune_cache c =
  c
  |> P.set_env "DUNE_CACHE" "enabled"
  |> P.set_env "DUNE_CACHE_TRANSPORT" "direct"

let safe_repo_list =
  [
    "git+https://github.com/na4zagin3/satyrographos-repo.git";
    "git+https://github.com/gfngfn/satysfi-external-repo.git";
    "https://opam.ocaml.org/";
    "git+https://github.com/ocaml/opam-repository.git";
  ] |> Set.of_list (module String)

let default_repo_list =
  [
    "satyrographos",
    "git+https://github.com/na4zagin3/satyrographos-repo.git";

    "satysfi-external",
    "git+https://github.com/gfngfn/satysfi-external-repo.git";

    "default",
    "https://opam.ocaml.org/";
  ]



let opam_clean_up_local_switch_com ?(path="./") () =
  let open P.Infix in
  P.run_bool
    "opam" [
    "switch";
    "set";
    "--dry-run";
    "--";
    path;
  ]
  >>= fun exists ->
  if exists
  then P.run "opam" [
      "switch";
      "remove";
      "--empty";
      "--yes";
      "--";
      path;
    ]
  else P.return ()


let opam_set_up_local_switch_com ?(repos=default_repo_list) ?(path="./") ~version () =
  let args = [
    "switch";
    "create";
    if Option.is_none version
    then "--empty"
    else "--no-install";
    "--yes";
    "--repositories";
    repos
    |> List.map ~f:(fun (name, url) -> name ^ "=" ^ url)
    |> String.concat ~sep:",";
    "--";
    path;
    Option.value ~default:"ocaml-base-compiler" version;
  ]
  in
  P.run "opam" args


type opam_dependency_wrapper = {
  name: string;
  repo: string;
  version: string;
}

let opam_installed_transitive_dependencies_com ~verbose:_ packages =
  let open P.Infix in
  let cmd =
    P.run "opam" [
      "list";
      "-i";
      "--color=never";
      "--columns";
      "name,repository,installed-version";
      "--separator=,";
      "--recursive";
      "--required-by"; String.concat ~sep:"," packages]
    |> P.capture_unit [P.Std_io.Stdout]
    >>| String.split_lines
    >>| List.filter ~f:(fun l -> String.is_prefix ~prefix:"#" l |> not)
    >>| List.filter_map ~f:(fun l ->
        match String.split_on_chars ~on:[','] l with
        | [name; repo; version] -> Some ({
            name = String.strip name;
            version = String.strip version;
            repo = String.strip repo
          })
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

let get_opam_repositories ~gt ~rt () =
  OpamGlobalState.repos_list gt
  |> List.map ~f:(OpamRepositoryState.get_repo rt)

let opam_install_com ~verbose packages =
  let packages =
    packages
    |> List.map ~f:(fun (name, version) ->
        sprintf "%s.%s" name version)
  in
  [
    ["install"; "--yes";];
    ["--switch=.";];
    if verbose
    then ["--verbose";]
    else [];
    packages;
  ]
  |> List.concat
  |> P.run "opam"
  |> with_dune_cache

let opam_install ~verbose packages =
  opam_install_com ~verbose packages
  |> P.eval

let opam_exec_run com args =
  [
    "exec";
    "--switch=.";
    "--";
  ] @ [com] @ args
  |> P.run "opam"
