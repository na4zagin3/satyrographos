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

Dep files
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps-make -S 0.0.5 --depfile deps.d -o empty.pdf --follow-required empty.saty
  Compatibility warning: You have opted in to use experimental features.
  $ cat deps.d
  empty.pdf: empty.saty
  
  deps.d: empty.saty
  
