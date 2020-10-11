Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ cat >second.satyh <<EOF
  > @import: third
  > @require: lib1
  > @require: lib2
  > EOF
  $ cat >third.satyh <<EOF
  > @require: lib3
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "lib3" [shape=ellipse, ];
    "second" [shape=doubleoctagon, ];
    "lib1" [shape=ellipse, ];
    "third" [shape=doubleoctagon, ];
    "lib2" [shape=ellipse, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "third.satyh" -> "lib3" [color="#004422", fontcolor="#004422",
                             label="@require: lib3", ];
    "second" -> "second.satyh" [color="#002288", fontcolor="#002288",
                                label=".satyh", ];
    "third" -> "third.satyh" [color="#002288", fontcolor="#002288",
                              label=".satyh", ];
    "second.satyh" -> "third" [color="#004422", fontcolor="#004422",
                               label="@import: third", ];
    "second.satyh" -> "lib1" [color="#004422", fontcolor="#004422",
                              label="@require: lib1", ];
    "second.satyh" -> "lib2" [color="#004422", fontcolor="#004422",
                              label="@require: lib2", ];
    "first.saty" -> "second" [color="#004422", fontcolor="#004422",
                              label="@import: second", ];
    "first.saty" -> "lib1" [color="#004422", fontcolor="#004422",
                            label="@require: lib1", ];
    
    }
