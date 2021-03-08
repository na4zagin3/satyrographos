Prepare SATySFi source
  $ cat >mdja.satysfi-md <<EOF
  > {
  >   "depends":["mdja"],
  >   "document":["Test.document"],
  >   "header-default":["(| title = {}; author = {}; |)"]
  > }
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 mdja.satysfi-md
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "mdja" [shape=ellipse, ];
    "mdja.satysfi-md" [shape=box, ];
    
    
    "mdja.satysfi-md" -> "mdja" [color="#117722", fontcolor="#117722",
                                 label="md depends mdja", ];
    
    }
