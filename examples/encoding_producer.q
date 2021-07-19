//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file encoding_producer.q
// @fileoverview
// Example producer who encodes messages with pipelines.
// @note
// This examples requires you to register schemas to the schema registry in advance.
// ```
// kafka]$ q q/kafka.q
// q)schema_id: .kafka.registerSchema[`localhost; 8081; `test1; "schema/person.avsc";.qtfm.AVRO]
// q)schema_id
// 1
// q)schema_id: .kafka.registerSchema[`localhost; 8081; `test2; "schema/person.avsc";.qtfm.AVRO]
// q)schema_id
// 1
// q)schema_id:.kafka.registerSchema[`localhost; 8081; `; "schema/google/descriptor.proto";.qtfm.PROTOBUF]
// q)schema_id
// 2
// q)schema_id:.kafka.registerSchema[`localhost; 8081; `; "schema/kdb_type_specifier.proto";.qtfm.PROTOBUF]
// q)schema_id
// 3
// q)schema_id: .kafka.registerSchema[`localhost; 8081; `test3; "schema/athlete.proto";.qtfm.PROTOBUF]
// q)schema_id
// 4
// ```

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

// Query schema information to schema registry for test1
schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test1; `latest];

// Create pipelines used for Avro encoding
avro_pipeline_name: `$string schemaInfo `id;
.qtfm.createNewPipeline[avro_pipeline_name];
.qtfm.addSerializationLayer[avro_pipeline_name; .qtfm.AVRO; schemaInfo `schema];
.qtfm.compile[avro_pipeline_name];

// Query schema information to schema registry for test3
schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test3; `latest];

// Create pipelines used for Protobuf encoding
// Add import path of proto file.
.qtfm.addProtoImportPath "schema/";
// Import proto file.
.qtfm.importProtoFile "athlete.proto";
protobuf_pipeline_name: `$string schemaInfo `id;
.qtfm.createNewPipeline[protobuf_pipeline_name];
// One message type must be passed for one topic. Various encoding for the same topic seems strange.
.qtfm.addSerializationLayer[protobuf_pipeline_name; .qtfm.PROTOBUF; `Person];
.qtfm.compile[protobuf_pipeline_name];

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i];

// Create topics.
topic1:.kafka.newTopic[producer;`test1;()!()];
topic2:.kafka.newTopic[producer;`test2;()!()];
topic3:.kafka.newTopic[producer;`test3;()!()];
topic4:.kafka.newTopic[producer;`test4;()!()];

// Callback for delivery report.
.kafka.dr_msg_cb:{[producer_idx; message]
  $["" ~ message `error;
    -1 "delivered:", .Q.s1 (message `msgtime; message `topic; "c"$message `data);
    -2 "delivery error:", message `error
  ];
 }

// Timer to publish messages.
n: 0;
.z.ts:{
  n+:1;
  turn: n mod 4;
  $[turn = 0;
    .kafka.publishWithHeaders[producer; topic1; .kafka.PARTITION_UA; `ID`First`Last`Phone`Age!(n; "David"; "Wilson"; "00111900"; 42i); "this is an Avro example"; `schema_id`something!(string avro_pipeline_name; "mogu-mogu")];
    turn = 1;
    .kafka.publishWithHeaders[producer; topic2; .kafka.PARTITION_UA; `ID`First`Last`Phone`Age!(n; "Michael"; "Ford"; "00778899"; 19i); "test2 uses the same Avro schema as test1"; enlist[`schema_id]!enlist string avro_pipeline_name];
    turn = 2;
    // Key `schema_type` must be included in a header
    .kafka.publishWithHeaders[producer; topic3; .kafka.PARTITION_UA; ("Shneider"; "Armstrong"; 1985.11.09; 36; ("gilberto"; "thunderbolt"); enlist[`100m]!enlist 0D00:00:07.034008900); "this is a Protobuf example"; `schema_id`schema_type`comment!(string protobuf_pipeline_name; "protobuf"; "powered kafkakdb")];
    // turn = 3
    .kafka.publishWithHeaders[producer; topic4; .kafka.PARTITION_UA; "sonomama"; "non-conversion example"; enlist[`comment]!enlist "'sonomama' means 'as it is'"]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

-1 "Published one message for each topic";
producer_meta:.kafka.getBrokerTopicConfig[producer; 5000i];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";
