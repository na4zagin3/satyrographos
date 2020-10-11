open Core

let expand_file_basename =
  let mode_name =
    let open Re in
    (* TODO Is this correct?  Shouldn't we put more restriction? *)
    rep (diff any (char ','))
  in
  let re =
    let open Re in
    seq [
      bos;
      rep any
      |> group;
      alt [
        str ".satyh";
        (* TODO Exclude these for Satysfi 0.0.3 and earlier *)
        seq [
          str ".satyh-";
          mode_name;
        ];
        str ".satyg";
      ]
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
          then Some (Re.Group.get g 2, file_path)
          else None)
    in
    if FileUtil.(test Is_dir dir)
    then FileUtil.(ls dir |> List.filter_map ~f)
    else []

let get_files ~outf r bs =
  match List.concat_map ~f:expand_file_basename bs with
  | [] ->
    Format.fprintf outf "Cannot read files for “%s”@." (Dependency.render_directive r);
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
  [@@deriving sexp, compare, hash, equal]
end

module Edge = struct
  type edge =
    | Directive of Dependency.directive
    | Mode of string
  [@@deriving sexp, compare, hash, equal]
  type t = edge option
  [@@deriving sexp, compare, hash, equal]
  let default = None
end

module G =
  Graph.Imperative.Digraph.ConcreteBidirectionalLabeled(Vertex)(Edge)

module Dot =
  Graph.Graphviz.Dot(struct
    include G
    let edge_attributes ((_f : vertex), (e : Edge.t), (_t : vertex)) =
      let edge_display = function
        | Edge.Directive d ->
          let label = Dependency.render_directive d in
          [`Label label; `Fontcolor 0x004422; `Color 0x004422]
        | Mode m ->
          [`Label m; `Fontcolor 0x002288; `Color 0x002288]
      in
      Option.value_map ~default:[] ~f:(edge_display) e
    let default_edge_attributes _ = []
    let get_subgraph _ = None
    let vertex_attributes (v : vertex) =
      match v with
      | Basename _ -> [`Shape `Doubleoctagon]
      | File _ -> [`Shape `Box]
      | Package _ -> [`Shape `Ellipse]
    let vertex_name (v : vertex) =
      match v with
      | Basename path -> sprintf "%S" path
      | File path -> sprintf "%S" path
      | Package p -> sprintf "%S" p
    let default_vertex_attributes _ = []
    let graph_attributes _ = []
  end)

let dependency_graph ~outf ?(follow_required=false) ~package_root_dirs files =
  let g = G.create () in
  let rec f file =
    let vf : G.vertex = File file in
    if G.mem_vertex g vf
    then ()
    else begin
      G.add_vertex g vf;
      Dependency.parse_file file
      |> Dependency.referred_file_basenames ~package_root_dirs
      |> List.iter ~f:(fun (directive, bs) ->
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
          get_files ~outf directive bs
          |> List.iter ~f:(fun (mode, path) ->
              let vt : G.vertex = File path in
              let e2 : Edge.t = Some (Mode mode) in
              f path;
              G.add_edge_e g (vm, e2, vt)
            )
        )
    end
  in
  List.iter ~f files;
  g
