Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second1
  > @import: second2/lib
  > EOF
  $ cat >second1.satyh <<EOF
  > EOF
  $ mkdir second2
  $ cat >second2/lib.satyg <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second1.satyh" [shape=box, ];
    "second1" [shape=doubleoctagon, ];
    "second2/lib.satyg" [shape=box, ];
    "second2/lib" [shape=doubleoctagon, ];
    "first.saty" [shape=box, ];
    
    
    "second1" -> "second1.satyh" [color="#000000", fontcolor="#000000",
                                  label=".satyh", style="dashed", ];
    "second2/lib" -> "second2/lib.satyg" [color="#000000", fontcolor="#000000",
                                          label=".satyg", style="dashed", ];
    "first.saty" -> "second1" [color="#002288", fontcolor="#002288",
                               label="@import: second1", ];
    "first.saty" -> "second2/lib" [color="#002288", fontcolor="#002288",
                                   label="@import: second2/lib", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second1.satyh" [shape=box, ];
    "second1" [shape=doubleoctagon, ];
    "second2/lib.satyg" [shape=box, ];
    "second2/lib" [shape=doubleoctagon, ];
    "first.saty" [shape=box, ];
    
    
    "second1" -> "second1.satyh" [color="#000000", fontcolor="#000000",
                                  label=".satyh", style="dashed", ];
    "second2/lib" -> "second2/lib.satyg" [color="#000000", fontcolor="#000000",
                                          label=".satyg", style="dashed", ];
    "first.saty" -> "second1" [color="#002288", fontcolor="#002288",
                               label="@import: second1", ];
    "first.saty" -> "second2/lib" [color="#002288", fontcolor="#002288",
                                   label="@import: second2/lib", ];
    
    }
