//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_producer.q
* @fileoverview
* Set up a producer and conducts a test while interacting with a consumer via the controller process. 
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
* @brief Producer configuration to create a client.
\
producer_configuration: .[!] flip(
  (`metadata.broker.list; BROKER_HOST_PORT);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Display pocess ID
-1 "producer PID: ", string .z.i;

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

// Create a producer.
producer:.kafka.newProducer[producer_configuration; 5000i];

// Create topics.
topic1:.kafka.newTopic[producer; `test1; ()!()];
topic2:.kafka.newTopic[producer; `test2; ()!()];
topic3:.kafka.newTopic[producer; `test3; ()!()];
topic4:.kafka.newTopic[producer; `test4; ()!()];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Start Process                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Connect to a controller.
CONTROLLER_SOCKET: hopen CONTROLLER_HANDLE;

CONTROLLER_SOCKET (`.control.submit_test; "get topic name 1"; .kafka.getTopicName topic1; `test1);
CONTROLLER_SOCKET (`.control.submit_test; "get topic name 2"; .kafka.getTopicName topic2; `test2);
CONTROLLER_SOCKET (`.control.submit_test; "get topic name 3"; .kafka.getTopicName topic3; `test3);
CONTROLLER_SOCKET (`.control.submit_test; "get topic name 4"; .kafka.getTopicName topic4; `test4);

CONTROLLER_SOCKET (`.control.submit_test; "register topics"; .kafka.PRODUCER_TOPIC_MAP; enlist[producer]!enlist (topic1; topic2; topic3; topic4));

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Publish message to enable offset
.kafka.publishWithHeaders[producer; topic1; 0i; `ID`First`Last`Phone`Age!(0; "David"; "Wilson"; "00111900"; 42i); "test1 first Avro"; `schema_id`something!(string avro_pipeline_name; "mogu-mogu")];
.kafka.publishWithHeaders[producer; topic2; 0i; `ID`First`Last`Phone`Age!(1; "Michael"; "Ford"; "00778899"; 19i); "test2 Avro"; enlist[`schema_id]!enlist string avro_pipeline_name];
.kafka.publishWithHeaders[producer; topic1; 0i; `ID`First`Last`Phone`Age!(2; "Mark"; "O'brien"; "01881440"; 29i); "test1 second Avro"; `schema_id`something!(string avro_pipeline_name; "mogu-mogu")];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Publish message
.kafka.publishWithHeaders[producer; topic1; 0i; `ID`First`Last`Phone`Age!(0; "David"; "Wilson"; "00111900"; 42i); "test1 first Avro"; `schema_id`something!(string avro_pipeline_name; "mogu-mogu")];
.kafka.publishWithHeaders[producer; topic2; 0i; `ID`First`Last`Phone`Age!(1; "Michael"; "Ford"; "00778899"; 19i); "test2 Avro"; enlist[`schema_id]!enlist string avro_pipeline_name];
.kafka.publishWithHeaders[producer; topic1; 0i; `ID`First`Last`Phone`Age!(2; "Mark"; "O'brien"; "01881440"; 29i); "test1 second Avro"; `schema_id`something!(string avro_pipeline_name; "mogu-mogu")];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Publish messages
.kafka.publishBatch[topic4; 0i; ("batch hello"; "batch hello2"); ""];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Publish with headers.
.kafka.publishWithHeaders[producer; topic3; 0i; ("Shneider"; "Armstrong"; 1985.11.09; 36; ("gilberto"; "thunderbolt"); enlist[`100m]!enlist 0D00:00:07.034008900); "this is a Protobuf example"; `schema_id`schema_type`comment!(string protobuf_pipeline_name; "protobuf"; "powered kafkakdb")];

// Yield waiting consumer
while[not CONTROLLER_SOCKET (`.control.yield_another; ::); (::)];

// Get current client type map
current_client_topic_map: .kafka.PRODUCER_TOPIC_MAP;

// Wait
CONTROLLER_SOCKET (`.control.barrier; ::);

// Delete topic1 to topic3
.kafka.deleteTopic each (topic1; topic2; topic3);

CONTROLLER_SOCKET (`.control.submit_test; "delete topic1 to topic3"; .kafka.PRODUCER_TOPIC_MAP[producer]; enlist topic4);

// Delete producer
//.kafka.deleteClient[producer];

//.test.ASSERT_EQ["delete producer"; .kafka.PRODUCER_TOPIC_MAP; producer _ current_client_topic_map]
//.test.ASSERT_EQ["delete producer - callback"; count .kafka.ERROR_CALLBACK_PER_CLIENT; 1]

// Delete topic2
.kafka.deleteTopic[topic4];

// Finish
CONTROLLER_SOCKET (`.control.finish; .z.i);

show "producer exit";
