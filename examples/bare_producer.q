//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file bare_producer.q
// @fileoverview
// Example producer for kafkakdb not linked with transformer. If data is not following the wired format,
//  it is automatically counted as non-schema-registry data and then passed through as it is (bytes).

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Library                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kafka.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Configuration
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`api.version.request; `true)
 );

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i];

// Create topics.
topic1:.kafka.newTopic[producer; `test1;()!()];
topic2:.kafka.newTopic[producer; `test2;()!()];

// Callback for delivery report.
.kafka.dr_msg_cb:{[producer_idx; message]
  $["" ~ message `error;
    -1 "delivered:", .Q.s1 (message `msgtime; message `topic; "c"$message `data);
    -2 "delivery error:", message `error
  ];
 }

// Timer to publish messages.
.z.ts:{
  n+:1;topic:$[n mod 2;topic1;topic2];
  .kafka.publish[topic;.kafka.PARTITION_UA; "Hello from producer";""];
  .kafka.publishWithHeaders[producer; topic; .kafka.PARTITION_UA; "locusts"; ""; `header1`header2!("firmament"; "divided")];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

producer_meta: .kafka.getBrokerTopicConfig[producer; 5000i];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";
