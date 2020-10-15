Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > EOF
  $ cat >second.satyh <<EOF
  > EOF
  $ cat >second.satyh-md <<EOF
  > EOF
  $ cat >second.satyg <<EOF
  > EOF

Generate dependency graphs for SATySFi 0.0.3
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --satysfi-version 0.0.3 first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }

Generate dependency graphs for SATySFi 0.0.5
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --satysfi-version 0.0.5 first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second.satyh-md" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "second.satyg" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyg" [color="#000000", fontcolor="#000000",
                                label=".satyg", style="dashed", ];
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "second" -> "second.satyh-md" [color="#000000", fontcolor="#000000",
                                   label=".satyh-md", style="dashed", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }
