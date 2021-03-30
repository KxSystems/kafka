//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file bench_producer.q
* @fileoverview
* Producer process for benchmark.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Load Library                     //
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
  (`fetch.wait.max.ms;`10);
  (`api.version.request; `true)
  );

// Which topic to publish
WHICH: 0b;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Functions                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

bench_pub:{[]
  topic: TOPICS WHICH;
  .kafka.publish[topic;.kafka.PARTITION_UA; "single hello";""];
  .kafka.publishBatch[topic; 0 0i; ("batch hello"; "batch hello"); ""];
  .kafka.publishWithHeaders[producer; topic; .kafka.PARTITION_UA; "hello with header"; ""; `header1`header2!("locusts"; "grasshopper")];
  WHICH:: not WHICH;
 }

.z.ts:{
  do[1500; bench_pub[]];
  if[00:00:10 < .z.p-START; -1 "Stop publisher"; exit 0];
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Setting                         //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Create a producer.
producer:.kafka.newProducer[kfk_cfg; 5000i];

// Create topics.
topic1:.kafka.newTopic[producer;`test1;()!()];
topic2:.kafka.newTopic[producer;`test2;()!()];

TOPICS: (topic1; topic2);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Start Process                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

START: .z.p;

\t 100
