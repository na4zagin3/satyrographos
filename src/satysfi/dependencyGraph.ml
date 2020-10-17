open Core

let expand_file_basename ~satysfi_version =
  let mode_name =
    let open Re in
    (* TODO Is this correct?  Shouldn't we put more restriction? *)
    rep (diff any (char ','))
  in
  let extensions_re =
    let open Re in
    List.concat [
      [str ".satyh";];
      if Version.read_local_packages satysfi_version
      then [
        seq [
          str ".satyh-";
          mode_name;
        ];
        str ".satyg";
      ]
      else [];
    ]
  in
  let re =
    let open Re in
    seq [
      bos;
      rep any
      |> group;
      alt extensions_re
      |> group;
      eos;
    ]
    |> compile
  in
  fun package_path ->
    let dir = FilePath.dirname package_path in
    let basename = FilePath.basename package_path in
    let f file_path =
      FilePath.basename file_path
      |> Re.exec_opt re
      |> Option.bind ~f:(fun g ->
          if Re.Group.get g 1 |> String.equal basename
          then Some (Re.Group.get g 2 |> Mode.of_extension_opt, file_path)
          else None)
    in
    if FileUtil.(test Is_dir dir)
    then FileUtil.(ls dir |> List.filter_map ~f)
    else []

let get_files ~outf ~expand_file_basename directive bs =
  match List.concat_map ~f:expand_file_basename bs with
  | [] ->
    Format.fprintf outf "Cannot read files for “%s”@." (Dependency.render_directive directive);
    Format.fprintf outf "@[<v 2>Candidate basenames:";
    List.iter bs ~f:(Format.fprintf outf "@;- %s");
    Format.fprintf outf "@]@.@.";
    []
  | files -> files

module Vertex = struct
  type t =
    | Basename of string
    | File of string
    | Package of string
    | MissingFile of string
  [@@deriving sexp, compare, hash, equal]
end

module Edge = struct
  type edge =
    | Directive of Dependency.directive
    | Mode of Mode.t
  [@@deriving sexp, compare, hash, equal]
  type t = edge option
  [@@deriving sexp, compare, hash, equal]
  let default = None
end

module G = struct
  module GOrig = Graph.Imperative.Digraph.ConcreteBidirectionalLabeled(Vertex)(Edge)
  include GOrig

  let edge_of_sexp =
    [%of_sexp: Vertex.t * Edge.t * Vertex.t]
  let sexp_of_edge =
    [%sexp_of: Vertex.t * Edge.t * Vertex.t]
  let compare_edge =
    [%compare: Vertex.t * Edge.t * Vertex.t]
  let hash_edge =
    [%hash: Vertex.t * Edge.t * Vertex.t]
  let hash_fold_edge =
    [%hash_fold: Vertex.t * Edge.t * Vertex.t]
  let equal_edge =
    [%equal: Vertex.t * Edge.t * Vertex.t]

  module E = struct
    include GOrig.E

    let t_of_sexp = edge_of_sexp
    let sexp_of_t = sexp_of_edge
    let compare = compare_edge
    let hash = hash_edge
    let hash_fold = hash_fold_edge
    let equal =  equal_edge
  end
end

module Oper =
  Graph.Oper.I(G)

module EdgeSet =
  Set.Make(G.E)

module VertexSet =
  Set.Make(Vertex)

module Dot =
  Graph.Graphviz.Dot(struct
    include G
    let edge_attributes ((_f : vertex), (e : Edge.t), (_t : vertex)) =
      let edge_display = function
        | Edge.Directive d ->
          let label = Dependency.render_directive d in
          let color = match d with
            | Require _ -> 0x117722
            | Import _ -> 0x002288
          in
          [`Label label; `Fontcolor color; `Color color]
        | Mode m ->
          let label = Mode.to_extension m in
          [`Label label; `Fontcolor 0x000000; `Color 0x000000; `Style `Dashed;]
      in
      Option.value_map ~default:[] ~f:(edge_display) e
    let default_edge_attributes _ = []
    let get_subgraph _ = None
    let vertex_attributes (v : vertex) =
      match v with
      | Basename _ -> [`Shape `Doubleoctagon]
      | File _ -> [`Shape `Box]
      | MissingFile _ -> [`Shape `Mdiamond]
      | Package _ -> [`Shape `Ellipse]
    let vertex_name (v : vertex) =
      match v with
      | Basename path -> sprintf "%S" path
      | File path -> sprintf "%S" path
      | MissingFile path -> sprintf "%S" path
      | Package p -> sprintf "%S" p
    let default_vertex_attributes _ = []
    let graph_attributes _ = []
  end)

let vertex_of_file_path path =
  if FileUtil.(test Is_file path)
  then Vertex.File path
  else MissingFile path

let dependency_graph ~outf ?(follow_required=false) ~package_root_dirs ~satysfi_version files =
  let expand_file_basename = expand_file_basename ~satysfi_version in
  let g = G.create () in
  let rec f file =
    let vf : G.vertex = vertex_of_file_path file in
    let add_files_read_by_directive ((directive: Dependency.directive), bs) =
      let vm =
        match directive, bs with
        | Import _, [b] ->
          Vertex.Basename b
        | Require p, _ ->
          Package p
        | directive, bs ->
          failwithf !"BUG: Directive %{sexp:Dependency.directive} has wrong number of candidate basenames %{sexp: string list}"
            directive bs ()
      in
      let e1 : Edge.t = Some (Directive directive) in
      G.add_edge_e g (vf, e1, vm);
      let recursion_enabled = match directive, follow_required with
        | Require _, false -> false
        | _ -> true
      in
      if recursion_enabled
      then
        get_files ~outf ~expand_file_basename directive bs
        |> List.iter ~f:(fun (mode, path) ->
            let vt : G.vertex = vertex_of_file_path path in
            let e2 : Edge.t = Option.map ~f:(fun m -> Edge.Mode m) mode in
            f path;
            G.add_edge_e g (vm, e2, vt)
          )
    in

    if G.mem_vertex g vf
    then ()
    else begin
      G.add_vertex g vf;
      match Dependency.parse_file_result file with
      | Result.Ok deps ->
        deps
        |> Dependency.referred_file_basenames ~package_root_dirs
        |> List.iter ~f:add_files_read_by_directive
      | Result.Error _exn ->
        (* TODO Connditionally output the exception *)
        ()
    end
  in
  List.iter ~f files;
  g

let subgraph_with_mode ~mode g =
  let g = G.copy g in
  let edges_to_be_removed =
    G.fold_edges_e (fun (e : G.edge) acc ->
        match e with
        | _, Some (Mode m), _ when not Mode.(m <=: mode) ->
          EdgeSet.add acc e
        | _ -> acc
      ) g EdgeSet.empty
  in
  EdgeSet.iter edges_to_be_removed ~f:(G.remove_edge_e g);
  g

let reachable_sinks g root_vertices =
  let gc = Oper.transitive_closure g in
  List.fold_left root_vertices ~init:VertexSet.empty ~f:(fun acc v ->
      let sinks =
        G.succ gc v
        |> VertexSet.of_list
        |> VertexSet.filter ~f:(fun v -> G.out_degree g v = 0)
      in
      VertexSet.union acc sinks
    )
  |> VertexSet.to_list

let%expect_test "reachable_sinks: test 1" =
  let g = G.create () in
  G.add_edge g (File "a.saty") (Basename "b");
  G.add_edge g (Basename "b") (File "b.satyh");
  G.add_edge g (File "b.satyh") (Basename "c");
  G.add_edge g (Basename "c") (File "b.satyg");
  G.add_edge g (File "b.satyh") (Package "p");
  G.add_edge g (File "b.saty-md") (Package "q");
  G.add_vertex g (File "d.saty");
  reachable_sinks g [File "a.saty"; File "d.saty"]
  |> List.iter ~f:(printf !"%{sexp:Vertex.t}\n");
  [%expect{|
    (File b.satyg)
    (Package p) |}]
