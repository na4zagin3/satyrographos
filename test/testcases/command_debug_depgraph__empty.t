Prepare SATySFi source
  $ cat >empty.saty <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 empty.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "empty.saty" [shape=box, ];
    
    
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --follow-required empty.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "empty.saty" [shape=box, ];
    
    
    
    }
