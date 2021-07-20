//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file decoding_consumer.q
// @fileoverview
// Example consumer who decodes messages with pipelines.
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
// q)schema_id:.kafka.registerSchema[`localhost; 8081; `; "schema/google/protobuf/descriptor.proto";.qtfm.PROTOBUF]
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
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit; `false);
    (`api.version.request; `true)
 );

// Table to store received data.
avro_data: ();
protobuf_data: ();
sonomama_data: ();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 25 200

// Query schema information to schema registry for test1
schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test1; `latest];

// Create pipelines used for decoding
avro_pipeline_name: `$string schemaInfo `id;
.qtfm.createNewPipeline[avro_pipeline_name];
.qtfm.addDeserializationLayer[avro_pipeline_name; .qtfm.AVRO; schemaInfo `schema];
.qtfm.compile[avro_pipeline_name];

// Query schema information to schema registry for test3
schemaInfo: .kafka.getSchemaInfoByTopic[`localhost; 8081; `test3; `latest];

// Create a pipeline used for Protobuf decoding
// Add import path of proto file.
.qtfm.addProtoImportPath "schema/";
// Import proto file.
.qtfm.importProtoFile "athlete.proto";
protobuf_pipeline_name: `$string schemaInfo `id;
.qtfm.createNewPipeline[protobuf_pipeline_name];
.qtfm.addDeserializationLayer[protobuf_pipeline_name; .qtfm.PROTOBUF; `Person];
.qtfm.compile[protobuf_pipeline_name];

show .qtfm.getPipelineInfo[protobuf_pipeline_name];

// Create a consumer.
consumer:.kafka.newConsumer[kfk_cfg; 5000i];

// Topics to subscribe to
topic1: `test1;
topic2: `test2;
topic3: `test3;
topic4: `test4;

// Topic callbacks for test1 and test2
topic_cb1:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  if[type[msg `data] ~ 99h; avro_data,: enlist msg];
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Topic callbacks for test3
topic_cb2:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  if[type[msg `data] ~ 0h; protobuf_data,: enlist msg];
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Topic callbacks for test4
topic_cb3:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  sonomama_data,: enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Callbac for committing an offset
.kafka.offset_commit_cb:{[consumer_idx;error;offsets]
  $[
    error ~ "Success";
    -1 "committed:", .Q.s1 offsets;
    -2 "commit error: ", error
  ];
 };

// Subscribe to topics from test1 to test4
.kafka.subscribe[consumer;topic1];
.kafka.subscribe[consumer;topic2];
.kafka.subscribe[consumer;topic3];
.kafka.subscribe[consumer;topic4];

// Register callback functions for the topic.
.kafka.registerConsumeTopicCallback[consumer; topic1; topic_cb1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic2; topic_cb1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic3; topic_cb2 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic4; topic_cb3 consumer];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

consumer_meta:.kafka.getBrokerTopicConfig[consumer; 5000i];

show consumer_meta`topics;
