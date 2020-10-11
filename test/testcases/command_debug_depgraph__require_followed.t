Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ cat >second.satyh <<EOF
  > @require: lib1
  > @require: lib2
  > EOF
  $ mkdir -p root/dist/packages
  $ cat >root/dist/packages/lib1.satyh <<EOF
  > EOF
  $ mkdir -p root/local/packages
  $ cat >root/local/packages/lib2.satyg <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --satysfi-root-dirs 'root' --follow-require first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "root/local/packages/lib2.satyg" [shape=box, ];
    "root/dist/packages/lib1.satyh" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "lib1" [shape=ellipse, ];
    "lib2" [shape=ellipse, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#002288", fontcolor="#002288",
                                label=".satyh", ];
    "lib1" -> "root/dist/packages/lib1.satyh" [color="#002288",
                                               fontcolor="#002288",
                                               label=".satyh", ];
    "lib2" -> "root/local/packages/lib2.satyg" [color="#002288",
                                                fontcolor="#002288",
                                                label=".satyg", ];
    "second.satyh" -> "lib1" [color="#004422", fontcolor="#004422",
                              label="@require: lib1", ];
    "second.satyh" -> "lib2" [color="#004422", fontcolor="#004422",
                              label="@require: lib2", ];
    "first.saty" -> "second" [color="#004422", fontcolor="#004422",
                              label="@import: second", ];
    "first.saty" -> "lib1" [color="#004422", fontcolor="#004422",
                            label="@require: lib1", ];
    
    }
