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
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second1.satyh" [shape=box, ];
    "second1" [shape=doubleoctagon, ];
    "second2/lib.satyg" [shape=box, ];
    "second2/lib" [shape=doubleoctagon, ];
    "first.saty" [shape=box, ];
    
    
    "second1" -> "second1.satyh" [color="#002288", fontcolor="#002288",
                                  label=".satyh", ];
    "second2/lib" -> "second2/lib.satyg" [color="#002288", fontcolor="#002288",
                                          label=".satyg", ];
    "first.saty" -> "second1" [color="#004422", fontcolor="#004422",
                               label="@import: second1", ];
    "first.saty" -> "second2/lib" [color="#004422", fontcolor="#004422",
                                   label="@import: second2/lib", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second1.satyh" [shape=box, ];
    "second1" [shape=doubleoctagon, ];
    "second2/lib.satyg" [shape=box, ];
    "second2/lib" [shape=doubleoctagon, ];
    "first.saty" [shape=box, ];
    
    
    "second1" -> "second1.satyh" [color="#002288", fontcolor="#002288",
                                  label=".satyh", ];
    "second2/lib" -> "second2/lib.satyg" [color="#002288", fontcolor="#002288",
                                          label=".satyg", ];
    "first.saty" -> "second1" [color="#004422", fontcolor="#004422",
                               label="@import: second1", ];
    "first.saty" -> "second2/lib" [color="#004422", fontcolor="#004422",
                                   label="@import: second2/lib", ];
    
    }
