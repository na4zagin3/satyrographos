open Core

(*
let satysfi_opam_registry () =
  OpamWrapper.get_satysfi_opam_registry None
  |> Option.map ~f:OpamFilename.Dir.to_string
*)

let read_opam_environment ?opam_switch () =
  let satysfi_opam_registry () =
    OpamWrapper.get_satysfi_opam_registry opam_switch
    |> Option.map ~f:OpamFilename.Dir.to_string
  in

  let reg = satysfi_opam_registry () in
  Format.(printf !"reg: %{sexp: string option}\n" reg);

  let opam_reg =
    OpamSatysfiRegistry.read (reg |> Option.value_exn ~message:"Failed to read OPAM repo")
  in
  Environment.{ empty with opam_reg; opam_switch; }
