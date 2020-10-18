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
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 first.saty
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
    
    
    "third.satyh" -> "lib3" [color="#117722", fontcolor="#117722",
                             label="@require: lib3", ];
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "third" -> "third.satyh" [color="#000000", fontcolor="#000000",
                              label=".satyh", style="dashed", ];
    "second.satyh" -> "third" [color="#002288", fontcolor="#002288",
                               label="@import: third", ];
    "second.satyh" -> "lib1" [color="#117722", fontcolor="#117722",
                              label="@require: lib1", ];
    "second.satyh" -> "lib2" [color="#117722", fontcolor="#117722",
                              label="@require: lib2", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    "first.saty" -> "lib1" [color="#117722", fontcolor="#117722",
                            label="@require: lib1", ];
    
    }
