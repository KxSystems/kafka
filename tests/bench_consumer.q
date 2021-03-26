//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file bench_consumer.q
* @fileoverview
* Consumer process for benchmark.
* @note The location of kafka broker director where `bin/` is included must be set on `KAFKA_BROKER_HOME`.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Load Library                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kafka.q
\c 500 500

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

// Topics to subscribe to
topic1:`test1;
topic2:`test2;

// Tables
consumer_table1: ();
consumer_table2: ();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Functions                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Callback function.
topic_callback1:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table1,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

topic_callback2:{[consumer;msg]
  msg[`rcvtime]:.z.p;
  msg[`data]:"c"$msg[`data];
  msg[`key]:"c"$msg[`key];
  msg[`headers]:"c"$msg[`headers];
  consumer_table2,:enlist msg;
  .kafka.commitOffsetsToTopicPartition[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b]
 };

display_stats:{
  if[0 = count consumer_table1, consumer_table2; :()];
  time:exec rcvtime-msgtime from (consumer_table1, consumer_table2) where not msgtime = 0Np;
  show `MAX`MIN`AVG`DEV`MED!(max; min; {`timespan$avg x}; {`timespan$dev x}; {`timespan$med x}) @\: time;
  show update {[n] $[1 = n; "*"; n#"*"]} each hist from select hist: count i by 1000000 xbar time from ([] time:asc time)
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Setting                         //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Clean up partition.
system getenv[`KAFKA_BROKER_HOME], "/bin/kafka-topics.sh --bootstrap-server localhost:9092 --topic test1 --delete";
system getenv[`KAFKA_BROKER_HOME], "/bin/kafka-topics.sh --bootstrap-server localhost:9092 --topic test2 --delete";

// Create a consumer.
consumer:.kafka.newConsumer[kfk_cfg; 5000i];

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kafka.subscribe[consumer;topic1];
.kafka.subscribe[consumer;topic2];

// Register callback functions for the topic.
.kafka.registerConsumeTopicCallback[consumer; topic1; topic_callback1 consumer];
.kafka.registerConsumeTopicCallback[consumer; topic2; topic_callback2 consumer];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Start Process                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Rebalancing will happen at the initial subscription.
while[0 = count .kafka.getCurrentAssignment[consumer]; system "sleep 5"];

-1 "Start producer!!";
system "nohup q bench_producer.q < /dev/null >> bench_producer.log 2>&1 &";
