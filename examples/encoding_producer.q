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

// Query schema information to schema registry
schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test1; `latest];

// Create pipelines used for encoding
pipeline_name: `$string schemaInfo `id;
.qtfm.createNewPipeline[pipeline_name];
.qtfm.addSerializationLayer[pipeline_name; .qtfm.AVRO; schemaInfo `schema];
.qtfm.compile[pipeline_name];

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i];

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
  $[n;
    .kafka.publishWithHeaders[producer; topic1; .kafka.PARTITION_UA; `ID`First`Last`Phone`Age!(2; "David"; "Wilson"; "00111900"; 42i); ""; `schema_id`something!(enlist "1"; "mogu-mogu")];
    .kafka.publishWithHeaders[producer; topic2; .kafka.PARTITION_UA; `ID`First`Last`Phone`Age!(14; "Michael"; "Ford"; "00778899"; 19i); ""; enlist[`schema_id]!enlist enlist "1"]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-1 "Published one message for each topic";
producer_meta:.kafka.getBrokerTopicConfig[producer; 5000i];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";

