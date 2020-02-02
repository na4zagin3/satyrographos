type repo = {
  repo: Repository.t;
  reg: Registry.t;
}

type t = {
  repo: repo option;
  opam_reg: OpamSatysfiRegistry.t option;
  dist_library_dir: string option;
}

