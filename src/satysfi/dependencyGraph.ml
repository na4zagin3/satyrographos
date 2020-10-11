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
    | File of string
    | Package of string
  [@@deriving sexp, compare, hash, equal]
end

let vertex_of_directive =
  let open Dependency in
  let open Vertex in
  function
  | Import f -> File f
  | Require f -> Package f

module Edge = struct
  type edge = {
    directive: Dependency.directive;
    mode: string option;
  }
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
      let open Dependency in
      let edge_display e =
        let Edge.{ directive; mode; } = e in
        let directive_display = render_directive directive in
        directive_display ^ Option.value_map ~default:"" ~f:(sprintf " (%s)") mode
      in
      let label = Option.value_map ~default:"" ~f:(edge_display) e in
      [`Label label; `Color 4711]
    let default_edge_attributes _ = []
    let get_subgraph _ = None
    let vertex_attributes _ = [`Shape `Box]
    let vertex_name (v : vertex) =
      match v with
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
      |> List.iter ~f:(
        let add_edge_from_directive directive =
          let vt : G.vertex = vertex_of_directive directive in
          let e : Edge.t = Some {
              directive;
              mode = None;
            } in
          G.add_edge_e g (vf, e, vt)
        in
        function
        | Dependency.Require _ as directive, _ when not follow_required ->
          add_edge_from_directive directive
        | directive, bs ->
          match get_files ~outf directive bs with
          | [] ->
            add_edge_from_directive directive
          | files ->
            List.iter files ~f:(fun (mode, path) ->
                let vt : G.vertex = File path in
                let e : Edge.t = Some {
                    directive;
                    mode = Some mode;
                  } in
                f path;
                G.add_edge_e g (vf, e, vt)
              );
      )
    end
  in
  List.iter ~f files;
  g
