Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > EOF
  $ cat >second.satyh <<EOF
  > @import: third
  > EOF
  $ cat >third.satyh <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    "second.satyh" [shape=box, ];
    
    
    "first.saty" -> "second.satyh" [color="#001267",
                                    label="@import: second (.satyh)", ];
    "second.satyh" -> "third.satyh" [color="#001267",
                                     label="@import: third (.satyh)", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    "second.satyh" [shape=box, ];
    
    
    "first.saty" -> "second.satyh" [color="#001267",
                                    label="@import: second (.satyh)", ];
    "second.satyh" -> "third.satyh" [color="#001267",
                                     label="@import: third (.satyh)", ];
    
    }
