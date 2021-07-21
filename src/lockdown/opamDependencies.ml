open Core

open LockdownFile
module P = Shexp_process
module OpamWrapper = Satyrographos.OpamWrapper

let get_opam_repositories ~gt ~rt () =
  OpamGlobalState.repos_list gt
  |> List.map ~f:(OpamRepositoryState.get_repo rt)

let get_opam_dependencies ~verbose packages =
  OpamGlobalState.with_ `Lock_none @@ fun gt ->
  OpamRepositoryState.with_ `Lock_none gt @@ fun rt ->
  let package_and_repos =
    OpamWrapper.opam_installed_transitive_dependencies_com ~verbose packages
    |> P.eval
  in
  let packages =
    package_and_repos
    |> List.map ~f:(fun {name; version; _} -> {name; version;})
  in
  let used_repos =
    package_and_repos
    |> List.map ~f:(fun {repo; _} -> repo)
    |> Set.of_list (module String)
  in
  used_repos
  |> Set.to_list
  |> Printf.printf !"Used repos: %{sexp: string list}\n";
  let all_repos = get_opam_repositories ~gt ~rt () in
  let repo_map =
    all_repos
    |> List.filter_map ~f:(fun r ->
        let name = OpamRepositoryName.to_string r.repo_name in
        if Set.mem used_repos name
        then Some (name, r)
        else begin
          OpamRepositoryBackend.to_string r |> Printf.printf "Not used: %s\n";
          None
        end
      )
    |> Map.of_alist_exn (module String)
  in
  let repos =
    all_repos
    |> List.filter ~f:(fun r ->
       let name = OpamRepositoryName.to_string r.repo_name in
       Set.mem used_repos name
      )
    |> List.map ~f:(fun r ->
        { name = OpamRepositoryName.to_string r.repo_name;
          url = OpamUrl.to_string r.repo_url;
        }
      )
  in
  let unsafe_repos =
    repo_map
    |> Map.filter ~f:(fun r ->
        OpamUrl.to_string r.repo_url
        |> Set.mem OpamWrapper.safe_repo_list
        |> not)
  in
  if Map.is_empty unsafe_repos |> not
  then begin
    unsafe_repos
    |> Map.to_alist
    |> List.map ~f:snd
    |> List.map ~f:OpamRepositoryBackend.to_string
    |> List.map ~f:(fun s -> "  " ^ s)
    |> String.concat ~sep:"\n"
    |> Printf.printf "[WARNING] The following repos are unsafe:\n%s\n";
    package_and_repos
    |> List.filter_map ~f:(fun {name; repo; _} ->
        if Map.mem unsafe_repos repo
        then Some (Printf.sprintf "  %s at %s" name repo)
        else None)
    |> String.concat ~sep:"\n"
    |> Printf.printf "Used by:\n%s\n";
  end;
  { packages; repos; }

let restore_opam_dependencies_com ~verbose (dependencies : opam_dependencies) =
  let packages =
    dependencies.packages
    |> List.map ~f:(fun {name; version;} ->
        name, version)
  in
  let install_com =
    OpamWrapper.opam_install_com ~verbose packages
  in
  let repos =
    dependencies.repos
    |> List.map ~f:(fun {name; url} -> name, url)
  in
  let open P.Infix in
  OpamWrapper.opam_clean_up_local_switch_com ()
  >> OpamWrapper.opam_set_up_local_switch_com ~repos ~version:None ()
  >> install_com


let restore_opam_dependencies ~verbose (dependencies : opam_dependencies) =
  restore_opam_dependencies_com ~verbose dependencies
  |> P.eval
