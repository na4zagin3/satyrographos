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
    "first.saty" [shape=box, ];
    "second2/lib.satyg" [shape=box, ];
    
    
    "first.saty" -> "second1.satyh" [color="#001267",
                                     label="@import: second1 (.satyh)", ];
    "first.saty" -> "second2/lib.satyg" [color="#001267",
                                         label="@import: second2/lib (.satyg)", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second1.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    "second2/lib.satyg" [shape=box, ];
    
    
    "first.saty" -> "second1.satyh" [color="#001267",
                                     label="@import: second1 (.satyh)", ];
    "first.saty" -> "second2/lib.satyg" [color="#001267",
                                         label="@import: second2/lib (.satyg)", ];
    
    }
