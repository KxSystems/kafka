//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file deprecated_producer.q
// @fileoverview
// Example producer for deprecated version. This version should not be linked to transformer.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Library                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kfk.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

kfk_cfg:(!) . flip(
  (`metadata.broker.list;`broker:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`api.version.request; `true)
 );

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Create a new producer
producer:.kfk.Producer[kfk_cfg];

// Create topics
topic1:.kfk.Topic[producer; `test1;()!()];
topic2:.kfk.Topic[producer; `test2;()!()];

// Callback for delivery report.
.kfk.drcb:{[producer_idx; message]
  $["" ~ message `error;
    -1 "delivered:", .Q.s1 (message `msgtime; message `topic; "c"$message `data);
    -2 "delivery error:", message `error
  ];
 };

.z.ts:{
  n+:1;
  topic:$[n mod 2; topic1; topic2];
  .kfk.Pub[topic; .kfk.PARTITION_UA; string x; ""]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

producer_meta: .kfk.Metadata[producer];
show producer_meta`topics;

-1 "Set timer with \\t 500 to publish a message each second to each topic.";
