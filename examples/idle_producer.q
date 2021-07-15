//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file idle_producer.q
// @fileoverview
// Example producer who does not encode messages with pipelines.

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

// Create pipelines used for encoding
.qtfm.createNewPipeline[`formalism];
.qtfm.addSerializationLayer[`formalism; .qtfm.NONE; (::)];
.qtfm.compile[`formalism];

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i; `formalism];

// Get pipeline map
pipeline_map: .kafka.getPipelinePerClient[];
show pipeline_map;

// Create topics.
topic1:.kafka.newTopic[producer;`test1;()!()]
topic2:.kafka.newTopic[producer;`test2;()!()]

// Callback for delivery report.
.kafka.dr_msg_cb:{[producer_idx; message]
  $["" ~ message `error;
    -1 "delivered:", .Q.s1 (message `msgtime; message `topic; "c"$message `data);
    -2 "delivery error:", message `error
  ];
 }

// Timer to publish messages.
n: 0b;
.z.ts:{
  n::not n;
  // The messages must be byte list or string. Here we use `.Q.s1` to communicate an image of what we want to send.
  $[n;
    .kafka.publish[producer; topic1; .kafka.PARTITION_UA; .Q.s1 `name`age`body`pets!("John"; 21; 173.1 67.2; `locust`grasshopper`vulture); ""];
    .kafka.publish[producer; topic2; .kafka.PARTITION_UA; .Q.s1 `title`ISBN`year`obsolete!("MyKDB+"; first 0Ng; 2021; 0b); ""]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-1 "Published one message for each topic";
producer_meta:.kafka.getBrokerTopicConfig[producer; 5000i];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";

