//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_consumer.q
* @fileoverview
* Set up a consumer and conducts a test while interacting with a producer via the controller process. 
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Load Library                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kafka.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments.
* @param confluenthost {symbol}: Host of Confluent platform
* @param brokerport {int}: Port of the Kafka broker.
* @param schemaregistryport {int}: Port of Confluent schema registry.
* @param controlport {string}: Port of the controller process.
\
COMMANDLINE_ARGUENTS: (@/)[.Q.opt .z.X; `confluenthost`brokerport`schemaregistryport`controlport; ({`$first x}; {"I"$first x}; {"I"$first x}; {first x})];

/
* @brief Endpoint of the Kafka broker.
\
BROKER_HOST_PORT: `$":" sv string COMMANDLINE_ARGUENTS[`confluenthost`brokerport];

/
* @brief Consumer configuration to create a client.
\
consumer_configuration: .[!] flip(
  (`metadata.broker.list; BROKER_HOST_PORT);
  (`group.id;`0);
  (`fetch.wait.max.ms;`10);
  (`statistics.interval.ms;`10000);
  (`enable.auto.commit; `false);
  (`api.version.request; `true)
 );

/
* @brief Endpoint of the controller process.
\
CONTROLLER_HANDLE: `$":" sv (""; "localhost"; COMMANDLINE_ARGUENTS `controlport);

/
* @brief Socket of the controller process.
\
CONTROLLER_SOCKET: (::);

/
* @brief Table to store messages from a producer.
\
avro_data: ();
protobuf_data: ();
sonomama_data: ();

/
* @brief Topics to subscribe to.
\
topic1: `test1;
topic2: `test2;
topic3: `test3;
topic4: `test4;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Topic callbacks for test1 and test2
avro_cb:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  //if[type[msg `data] ~ 99h; avro_data,: enlist msg];
  avro_data,: enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Topic callbacks for test3
protobuf_cb:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  //if[type[msg `data] ~ 0h; protobuf_data,: enlist msg];
  protobuf_data,: enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Topic callbacks for test4
sonomama_cb:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  if[`headers in key msg; msg[`headers]: "c"$msg `headers];
  if[`key in key msg; msg[`key]: "c"$msg `key];
  sonomama_data,: enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Display pocess ID
-1 "consumer PID: ", string .z.i;

//%% Set up Avro pipeline %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// Query schema information to schema registry for test1
//schemaInfo: .kafka.getSchemaInfoByTopic[COMMANDLINE_ARGUENTS `confluenthost; COMMANDLINE_ARGUENTS `schemaregistryport; `test1; `latest];

// Create pipelines used for Avro encoding
avro_pipeline_name: `1; //`$string schemaInfo `id;
.qtfm.createNewPipeline[avro_pipeline_name];
.qtfm.addSerializationLayer[avro_pipeline_name; .qtfm.AVRO; hsym `$"../schema/person.avsc"]; //schemaInfo `schema];
.qtfm.compile[avro_pipeline_name];

//%% Set up Protobuf pipeline %%//vvvvvvvvvvvvvvvvvvvvvvvv/

// Query schema information to schema registry for test3
//schemaInfo: .kafka.getSchemaInfoByTopic[COMMANDLINE_ARGUENTS `confluenthost; COMMANDLINE_ARGUENTS `schemaregistryport; `test3; `latest];

// Add import path of proto file.
.qtfm.addProtoImportPath "../schema/";
// Import proto file.
.qtfm.importProtoFile "athlete.proto";

// Create pipelines used for Protobuf encoding
protobuf_pipeline_name: `4; //`$string schemaInfo `id;
.qtfm.createNewPipeline[protobuf_pipeline_name];
// One message type must be passed for one topic. Various encoding for the same topic seems strange.
.qtfm.addSerializationLayer[protobuf_pipeline_name; .qtfm.PROTOBUF; `Person];
.qtfm.compile[protobuf_pipeline_name];

// Create a consumer
consumer: .kafka.newConsumer[consumer_configuration; 5000i];

// Register callback functions for the consumer
.kafka.registerConsumeTopicCallback[consumer; `test1; avro_cb consumer];
.kafka.registerConsumeTopicCallback[consumer; `test2; avro_cb consumer];
.kafka.registerConsumeTopicCallback[consumer; `test3; protobuf_cb consumer];
.kafka.registerConsumeTopicCallback[consumer; `test4; sonomama_cb consumer];

// Subscribe to topic1 and topic2.
.kafka.subscribe[consumer; `test1];
.kafka.subscribe[consumer; `test2];
.kafka.subscribe[consumer; `test3];
.kafka.subscribe[consumer; `test4];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Start Process                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Connect to a controller.
CONTROLLER_SOCKET: hopen CONTROLLER_HANDLE;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Wait for broker to be ready
while[() ~ .kafka.getCurrentAssignment[consumer]; system "sleep 1"];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`test1`test2`test3`test4; 4#0i; 4#-1001; 4#enlist "");
CONTROLLER_SOCKET (`.control.submit_test; "initial assignment"; .kafka.getCurrentAssignment[consumer]; current_assignment);

// Expected subscription information
current_subscription: flip `topic`partition`offset`metadata!(`test1`test2`test3`test4; 4#0i; 4#-1001; 4#enlist "");

CONTROLLER_SOCKET (`.control.submit_test; "subscription config"; .kafka.getCurrentSubscription[consumer]; current_subscription);

// Add topic-partition 2 for topic1.
.kafka.addTopicPartitionToAssignment[consumer; enlist[`test1]!enlist 1i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`test1`test1`test2`test3`test4; 0 1 0 0 0i; 5#-1001; 5#enlist "");

CONTROLLER_SOCKET (`.control.submit_test; "add partition 1 to test1"; .kafka.getCurrentAssignment[consumer]; current_assignment);

// Delete topic-partition 2 from topic1.
.kafka.deleteTopicPartitionFromAssignment[consumer; enlist[`test1]!enlist 1i];

// Expected assignment information
current_assignment: flip `topic`partition`offset`metadata!(`test1`test2`test3`test4; 4#0i; 4#-1001; 4#enlist "");

CONTROLLER_SOCKET (`.control.submit_test; "delete partition 1 from test1"; .kafka.getCurrentAssignment[consumer]; current_assignment);

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Get current number of rows.
current_offset_1: last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test1; enlist 0i];
current_offset_2: last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test2; enlist 0i];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Ensure time elapses for 60 seconds.
CONTROLLER_SOCKET (`.control.submit_test; "get earliest offset since 1 minute ago for test1"; last exec offset from .kafka.getEarliestOffsetsForTimes[consumer; `test1; enlist[0i]!enlist .z.p-0D00:01:00.000000000; 1000]; current_offset_1);
CONTROLLER_SOCKET (`.control.submit_test; "get earliest offset since 1 minute ago for test2"; last exec offset from .kafka.getEarliestOffsetsForTimes[consumer; `test2; enlist[0i]!enlist .z.p-0D00:01:00.000000000; 1000]; current_offset_2);

show avro_data;

CONTROLLER_SOCKET (`.control.submit_test; "offset for test1 after publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test1; enlist 0i]) - current_offset_1; 2);
CONTROLLER_SOCKET (`.control.submit_test; "offset for test2 after publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test2; enlist 0i]) - current_offset_2; 1);

// Get current number of rows.
current_offset_1:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test1; enlist 0i];
current_offset_2:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test2; enlist 0i];

// Get current table sizes.
current_num_rows_avro: count avro_data;

// Assign new offset
.kafka.assignNewOffsetsToTopicPartition[consumer; `test1; enlist[0i]!enlist 1];
.kafka.assignNewOffsetsToTopicPartition[consumer; `test2; enlist[0i]!enlist 1];

// Read 
CONTROLLER_SOCKET (`.control.submit_test; "assign new offset for test1 and test2 reloads messages til latest"; count[avro_data]-current_num_rows_avro; current_offset_1 + current_offset_2);

// Get current number of rows.
current_offset_4:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test4; enlist 0i];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

show sonomama_data;

CONTROLLER_SOCKET (`.control.submit_test; "offset proceeds for test4 after batch publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test4; enlist 0i]) - current_offset_4; 2);

current_offset_3:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test3; enlist 0i];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

show protobuf_data;

CONTROLLER_SOCKET (`.control.submit_test; "offset proceeds for test3 after publish with headers"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `test3; enlist 0i]) - current_offset_3; 1);

// Unsubscribe
.kafka.unsubscribe[consumer];

CONTROLLER_SOCKET (`.control.submit_test; "unsubscribe - subscription"; .kafka.getCurrentSubscription consumer; ());
CONTROLLER_SOCKET (`.control.submit_test; "unsubscribe - callback"; count .kafka.CONSUME_TOPIC_CALLBACK_PER_CONSUMER consumer; 0);

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Get current client type map
//current_client_map: .kafka.CLIENT_TYPE_MAP;

// Delete consumer
//.kafka.deleteClient[consumer];

//CONTROLLER_SOCKET (`.control.submit_test; "delete consumer"; .kafka.CLIENT_TYPE_MAP; consumer _ .kafka.CLIENT_TYPE_MAP);

// Finish
CONTROLLER_SOCKET (`.control.finish; .z.i);

show "consumer exit";
