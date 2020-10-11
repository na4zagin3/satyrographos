Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ mkdir root

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --satysfi-root-dirs 'root' --follow-require first.saty
  Compatibility warning: You have opted in to use experimental features.
  Cannot read files for “@import: second”
  Candidate basenames:
    - second
  
  Cannot read files for “@require: lib1”
  Candidate basenames:
    - root/dist/packages/lib1
    - root/local/packages/lib1
  
  digraph G {
    "second" [shape=box, ];
    "first.saty" [shape=box, ];
    "lib1" [shape=box, ];
    
    
    "first.saty" -> "second" [color="#001267", label="@import: second", ];
    "first.saty" -> "lib1" [color="#001267", label="@require: lib1", ];
    
    }
