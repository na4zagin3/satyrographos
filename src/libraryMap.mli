val transitive_closure :
  (string, Library.Dependency.t, Library.StringSet.Elt.comparator_witness) Base.Map.t ->
  Library.Dependency.t -> Library.Dependency.t
