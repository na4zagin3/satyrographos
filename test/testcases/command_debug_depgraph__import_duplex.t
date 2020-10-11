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
    "second" [shape=doubleoctagon, ];
    "third" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#002288", fontcolor="#002288",
                                label=".satyh", ];
    "third" -> "third.satyh" [color="#002288", fontcolor="#002288",
                              label=".satyh", ];
    "second.satyh" -> "third" [color="#004422", fontcolor="#004422",
                               label="@import: third", ];
    "first.saty" -> "second" [color="#004422", fontcolor="#004422",
                              label="@import: second", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "third" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#002288", fontcolor="#002288",
                                label=".satyh", ];
    "third" -> "third.satyh" [color="#002288", fontcolor="#002288",
                              label=".satyh", ];
    "second.satyh" -> "third" [color="#004422", fontcolor="#004422",
                               label="@import: third", ];
    "first.saty" -> "second" [color="#004422", fontcolor="#004422",
                              label="@import: second", ];
    
    }
