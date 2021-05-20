//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file encoding_producer.q
// @fileoverview
// Example producer who encodes messages with pipelines.

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
.qtfm.createNewPipeline[`jsonian];
.qtfm.addSerializationLayer[`jsonian; .qtfm.JSON; (::)];
.qtfm.addSerializationLayer[`jsonian; .qtfm.ZSTD; 3i];
.qtfm.compile[`jsonian];

.qtfm.createNewPipeline[`avroer];
.qtfm.addSerializationLayer[`avroer; .qtfm.AVRO; "../schema/person.avsc"];
.qtfm.compile[`avroer];

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i]

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
  n:: not n;
  $[n;
    .kafka.publishWithHeaders[producer; topic1; .kafka.PARTITION_UA; `name`age`body`pets!("John"; 21; 173.1 67.2; `locust`grasshopper`vulture); ""; `encoder`decoder!("jsonian"; "pomelanian")];
    .kafka.publishWithHeaders[producer; topic2; .kafka.PARTITION_UA; `ID`First`Last`Phone`Age!(2; "Michael"; "Ford"; "0000A"; 33i); ""; `encoder`decoder!("avroer"; "eyebrow")]
  ];
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-1 "Published one message for each topic";
producer_meta:.kafka.getBrokerTopicConfig[producer; 5000i];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";

