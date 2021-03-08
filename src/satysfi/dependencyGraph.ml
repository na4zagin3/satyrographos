open Core

module Location = Satyrographos.Location

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
    | Directive of Location.t * Dependency.directive
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

  let sexp_of_t g =
    let edges =
      GOrig.fold_edges_e (fun e acc -> e :: acc) g []
    in
    let vertices =
      GOrig.fold_vertex (fun v acc -> v :: acc) g []
    in
    [%sexp_of: Vertex.t list * E.t list] (vertices, edges)
end

module Oper =
  Graph.Oper.I(G)

module EdgeSet =
  Set.Make(G.E)

module VertexSet =
  Set.Make(Vertex)
module VertexMap =
  Map.Make(Vertex)

module Dot =
  Graph.Graphviz.Dot(struct
    include G
    let edge_attributes ((_f : vertex), (e : Edge.t), (_t : vertex)) =
      let edge_display = function
        | Edge.Directive (_, d) ->
          let label = Dependency.render_directive d in
          let color = match d with
            | Require _
            | MdDepends _ ->
              0x117722
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
    let add_files_read_by_directive (off, (directive: Dependency.directive), bs) =
      let vm =
        match directive, bs with
        | Import _, [b] ->
          Vertex.Basename b
        | Require p, _
        | MdDepends p, _ ->
          Package p
        | Import _, bs ->
          failwithf !"BUG: Directive %{sexp:Dependency.directive} has wrong number of candidate basenames %{sexp: string list}"
            directive bs ()
      in
      let e1 : Edge.t = Some (Directive (off, directive)) in
      G.add_edge_e g (vf, e1, vm);
      let recursion_enabled = match directive, follow_required with
        | _, true ->
          true
        | Require _, false
        | MdDepends _, false ->
          false
        | Import _, _ -> true
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
  let edges_to_be_removed, vertices_to_be_removed =
    G.fold_vertex (fun (v : Vertex.t) (acc_nodes, acc_vertices) ->
        let filter_edge e =
          match e with
          | _, Some (Edge.Mode m), _ ->
            Some (m, e)
          | _ -> None
        in
        let edges =
          G.succ_e g v
          |> List.filter_map ~f:filter_edge
        in
        let modes =
          List.map edges ~f:fst
        in
        let chosen_mode =
          modes
          |> List.filter ~f:(fun m -> Mode.(m <=: mode))
          |> List.sort ~compare:Mode.compare
          |> List.last
        in
        let edges =
          List.filter_map edges ~f:(fun (m, e) ->
              Option.some_if ([%equal: Mode.t option] (Some m) chosen_mode |> not) e
            )
          |> EdgeSet.of_list
        in
        let vertices acc =
          match v with
          | Basename _
          | Package _
          | MissingFile _ ->
            acc
          | File fn ->
            let fmode =
              Mode.of_basename_opt fn
            in
            Option.value_map fmode ~default:acc ~f:(fun fmode ->
                if Mode.(fmode <=: mode)
                then acc
                else VertexSet.add acc v
              )
        in
        EdgeSet.union edges acc_nodes,
        vertices acc_vertices
      ) g (EdgeSet.empty, VertexSet.empty)
  in
  EdgeSet.iter edges_to_be_removed ~f:(G.remove_edge_e g);
  VertexSet.iter vertices_to_be_removed ~f:(G.remove_vertex g);
  g

let%expect_test "subgraph_with_mode: test 1" =
  let g = G.create () in
  let print_result (g : G.t) : unit =
    let edges =
      let edge_list = ref [] in
      G.iter_edges_e
        (fun e -> edge_list := e :: !edge_list)
        g;
      !edge_list
    in
    edges
    |> List.sort ~compare:[%compare: (Vertex.t * Edge.t * Vertex.t)]
    |> printf !"%{sexp:(Vertex.t * Edge.t * Vertex.t) list}\n"
  in
  let test g mode =
    subgraph_with_mode g ~mode
    |> print_result;
    printf "\n"
  in
  let line f l = Location.{
      path=f;
      range=Some (Line l);
    }
  in
  G.add_edge_e g (File "a.saty", Some (Edge.Directive (line "a.saty" 0, Dependency.Require "b")), Basename "b");
  G.add_edge_e g (Basename "b", Some (Edge.Mode Mode.Pdf), File "b.satyh");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 1, Dependency.Require "c")), Basename "c");
  G.add_edge_e g (Basename "c", Some (Edge.Mode Mode.Generic), File "c.satyg");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 2, Dependency.Require "p")), Package "p");
  G.add_edge_e g (Basename "b", Some (Edge.Mode Mode.(Text "md")), File "b.satyh-md");
  G.add_edge_e g (File "b.satyh-md", Some (Edge.Directive (line "b.satyh-md" 3, Dependency.Require "q")), Package "q");
  G.add_edge_e g (File "c.satyg", Some (Edge.Directive (line "c.satyg" 4, Dependency.Require "b")), Basename "b");
  G.add_vertex g (File "d.saty");
  test g Mode.Pdf;
  [%expect{|
    (((Basename b) ((Mode Pdf)) (File b.satyh))
     ((Basename c) ((Mode Generic)) (File c.satyg))
     ((File a.saty) ((Directive ((path a.saty) (range ((Line 0)))) (Require b)))
      (Basename b))
     ((File b.satyh)
      ((Directive ((path b.satyh) (range ((Line 1)))) (Require c))) (Basename c))
     ((File b.satyh)
      ((Directive ((path b.satyh) (range ((Line 2)))) (Require p))) (Package p))
     ((File c.satyg)
      ((Directive ((path c.satyg) (range ((Line 4)))) (Require b))) (Basename b))) |}]

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
  G.add_edge g (Basename "c") (File "c.satyg");
  G.add_edge g (File "b.satyh") (Package "p");
  G.add_edge g (File "b.saty-md") (Package "q");
  G.add_vertex g (File "d.saty");
  reachable_sinks g [File "a.saty"; File "d.saty"]
  |> List.iter ~f:(printf !"%{sexp:Vertex.t}\n");
  [%expect{|
    (File c.satyg)
    (Package p) |}]

let revese_lookup_directive dep_graph v_orig =
  let rec sub directive (v, e, _) =
    let directive = match e with
      | Some (Edge.Directive (l, d)) -> Some (l, d)
      | _ -> directive
    in
    match v with
    | Vertex.File path
    | Vertex.MissingFile path ->
      let directive =
        Option.value_exn directive ~message:(
          sprintf !"BUG: reverse_lookup_directive: %{sexp:Vertex.t} depends on file %{sexp:Vertex.t} without any directives."
            v
            v_orig
        )
      in
      [directive, path]
    | Vertex.Basename _
    | Vertex.Package _ ->
      G.pred_e dep_graph v
      |> List.concat_map ~f:(sub directive)
  in
  G.pred_e dep_graph v_orig
  |> List.concat_map ~f:(sub None)

let%expect_test "revese_lookup_directive: test 1" =
  let g = G.create () in
  let print_result (d, p) : unit =
    printf !"%s: %{sexp:Location.t * Dependency.directive}\n" p d
  in
  let test v =
    printf !"%{sexp:Vertex.t}\n" v;
    revese_lookup_directive g v
    |> List.iter ~f:print_result;
    printf "\n"
  in
  let line f l = Location.{
      path=f;
      range=Some (Line l);
    }
  in
  G.add_edge_e g (File "a.saty", Some (Edge.Directive (line "a.saty" 0, Dependency.Require "b")), Basename "b");
  G.add_edge_e g (Basename "b", Some (Edge.Mode Mode.Pdf), File "b.satyh");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 1, Dependency.Require "c")), Basename "c");
  G.add_edge_e g (Basename "c", Some (Edge.Mode Mode.Generic), File "c.satyg");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 2, Dependency.Require "p")), Package "p");
  G.add_edge_e g (File "b.satyh-md", Some (Edge.Directive (line "b.satyh-md" 3, Dependency.Require "q")), Package "q");
  G.add_vertex g (File "d.saty");
  test (File "c.satyg");
  test (Basename "b");
  [%expect{|
    (File c.satyg)
    b.satyh: (((path b.satyh) (range ((Line 1)))) (Require c))

    (Basename b)
    a.saty: (((path a.saty) (range ((Line 0)))) (Require b)) |}]

module Dijkstra = Graph.Path.Dijkstra(G)(struct
    type edge = G.E.t
    type t = int
    let weight _ = 1
    let compare = compare_int
    let add = (+)
    let zero = 0
  end)

(** Shortest paths from sources to each sink.
*)
let path_directives dep_graph sources sinks =
  let paths_to_sink sink =
    List.filter_map sources ~f:(fun source ->
        Result.try_with (fun () ->
            let ps, _ = Dijkstra.shortest_path dep_graph source sink in
            List.filter_map ps ~f:(function
                | _, Some (Edge.Directive (l, d)), _ ->
                  Some (l, d)
                | _, _, _ -> None
              )
          )
        |> Result.ok
      )
  in
  Sequence.of_list sinks
  |> Sequence.map ~f:(fun sink -> sink, paths_to_sink sink)
  |> VertexMap.of_sequence_exn

let%expect_test "path_directives: test 1" =
  let g = G.create () in
  let print_result paths : unit =
    printf !"%{sexp:(Location.t * Dependency.directive) list list VertexMap.t}\n" paths
  in
  let test sources sinks  =
    printf !"%{sexp:Vertex.t list} --> %{sexp:Vertex.t list}\n" sources sinks;
    path_directives g sources sinks
    |> print_result;
    printf "\n"
  in
  let line f l = Location.{
      path=f;
      range=Some (Line l);
    }
  in
  G.add_edge_e g (File "a.saty", Some (Edge.Directive (line "a.saty" 0, Dependency.Require "b")), Basename "b");
  G.add_edge_e g (Basename "b", Some (Edge.Mode Mode.Pdf), File "b.satyh");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 1, Dependency.Require "c")), Basename "c");
  G.add_edge_e g (Basename "c", Some (Edge.Mode Mode.Generic), File "c.satyg");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 2, Dependency.Require "p")), Package "p");
  G.add_edge_e g (File "b.satyh-md", Some (Edge.Directive (line "b.satyh-md" 3, Dependency.Require "q")), Package "q");
  G.add_vertex g (File "d.saty");
  test [File "a.saty"; File "d.saty"] [File "c.satyg"; Package "p"];
  [%expect{|
    ((File a.saty) (File d.saty)) --> ((File c.satyg) (Package p))
    (((File c.satyg)
      (((((path a.saty) (range ((Line 0)))) (Require b))
        (((path b.satyh) (range ((Line 1)))) (Require c)))))
     ((Package p)
      (((((path a.saty) (range ((Line 0)))) (Require b))
        (((path b.satyh) (range ((Line 2)))) (Require p)))))) |}]

module Components = Graph.Components.Make(G)

let get_cycle reduced_dep_graph start =
  let rec sub acc (_, e, vt) =
    if Vertex.equal start vt
    then acc
    else
      let acc = match e with
        | Some (Edge.Directive (l, d)) ->
          (l, d) :: acc
        | _ -> acc
      in
      G.succ_e reduced_dep_graph vt
      |> List.concat_map ~f:(sub acc)
  in
    G.succ_e reduced_dep_graph start
    |> List.concat_map ~f:(sub [])

(** Extract cyclic edges
*)
let cyclic_edges dep_graph =
  let closure =
    Oper.transitive_closure dep_graph
  in
  let reduced_dep_graph =
    Oper.transitive_reduction dep_graph
  in
  Components.scc_list closure
  |> List.filter_map ~f:(function
      | (_ :: _ :: _) as vs->
        let vs = VertexSet.of_list vs in
        (* TODO Optimize *)
        G.fold_edges_e (fun ((vf, _, vt) as e) acc ->
            if VertexSet.mem vs vf && VertexSet.mem vs vt
            then e :: acc
            else acc)
          reduced_dep_graph
          []
        |> Option.some
      | _ ->
        None
    )

let%expect_test "cyclic_edges: test 1" =
  let g = G.create () in
  let print_result paths : unit =
    paths
    |> List.map ~f:(List.sort ~compare:[%compare: (Vertex.t * Edge.t * Vertex.t)])
    |> List.sort ~compare:[%compare: (Vertex.t * Edge.t * Vertex.t) list]
    |> printf !"%{sexp:(Vertex.t * Edge.t * Vertex.t) list list}\n"
  in
  let test g  =
    cyclic_edges g
    |> print_result;
    printf "\n"
  in
  let line f l = Location.{
      path=f;
      range=Some (Line l);
    }
  in
  G.add_edge_e g (File "a.saty", Some (Edge.Directive (line "a.saty" 0, Dependency.Require "b")), Basename "b");
  G.add_edge_e g (Basename "b", Some (Edge.Mode Mode.Pdf), File "b.satyh");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 1, Dependency.Require "c")), Basename "c");
  G.add_edge_e g (Basename "c", Some (Edge.Mode Mode.Generic), File "c.satyg");
  G.add_edge_e g (File "b.satyh", Some (Edge.Directive (line "b.satyh" 2, Dependency.Require "p")), Package "p");
  G.add_edge_e g (File "b.satyh-md", Some (Edge.Directive (line "b.satyh-md" 3, Dependency.Require "q")), Package "q");
  G.add_edge_e g (File "c.satyg", Some (Edge.Directive (line "c.satyg" 4, Dependency.Require "b")), Basename "b");
  G.add_vertex g (File "d.saty");
  test g;
  [%expect{|
    ((((Basename b) ((Mode Pdf)) (File b.satyh))
      ((Basename c) ((Mode Generic)) (File c.satyg))
      ((File b.satyh)
       ((Directive ((path b.satyh) (range ((Line 1)))) (Require c)))
       (Basename c))
      ((File c.satyg)
       ((Directive ((path c.satyg) (range ((Line 4)))) (Require b)))
       (Basename b)))) |}]

let cyclic_directives dep_graph =
  cyclic_edges dep_graph
  |> List.map ~f:(fun edges ->
      List.filter_map edges ~f:(function
          | _, Some (Edge.Directive (l, d)), _ -> Some (l, d)
          | _ -> None
        )
        (* TODO Should be ordered with the graph structure rather than the lexicographical order. *)
      |> List.sort ~compare:[%compare: Location.t * Dependency.directive]
    )

let reachable_files dep_graph sources =
  let closure =
    Oper.transitive_closure dep_graph
  in
  let f source =
    G.succ closure (Vertex.File source)
    |> List.filter_map ~f:(function
        | File path -> Some path
        | _ -> None
      )
  in
  List.map sources ~f:(fun source -> source, f source)

(* TODO Improve this *)
let escape_makefile_filename name =
  String.concat_map name ~f:(function
      | '$' -> "$$"
      | '\'' -> {|'\''|}
      | ' ' -> {|\ |}
      | c -> String.of_char c
    )

module Makefile = struct
  let expand_deps deps =
    let current_targets =
      List.map deps ~f:fst
      |> Set.of_list (module String)
    in
    let additional_targets =
      List.concat_map deps ~f:snd
      |> Set.of_list (module String)
    in
    let additional_targets =
      Set.diff additional_targets current_targets
      |> Set.to_list
      |> List.map ~f:(fun target -> target, [])
    in
    deps @ additional_targets

  let to_string deps =
    let buf = Buffer.create 100 in
    let f = Format.make_formatter (fun str pos len -> Buffer.add_substring buf str ~pos ~len) ignore in
    List.iter deps ~f:(fun (target, deps) ->
        Format.fprintf f "%s:" target;
        List.iter deps ~f:(fun dep ->
            escape_makefile_filename dep
            |> Format.fprintf f " %s"
          );
        Format.fprintf f "@.@.";
      );
    Buffer.contents buf
end

let%expect_test "Makefile.to_string: empty" =
  Makefile.to_string []
  |> print_endline

let%expect_test "Makefile.to_string: simple" =
  Makefile.to_string [
    "a.saty", ["b.satyh"];
    "b.saty", [];
    "c.saty", ["d.satyh"; "e.satyh"];
  ]
  |> print_endline;
  [%expect {|
    a.saty: b.satyh

    b.saty:

    c.saty: d.satyh e.satyh |}]

