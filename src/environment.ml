type depot = {
  repo: Repository.t;
  reg: Registry.t;
}

type t = {
  depot: depot option;
  opam_reg: OpamSatysfiRegistry.t option;
  dist_library_dir: string option;
}

