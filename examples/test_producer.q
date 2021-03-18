\l ../q/kafka.q
kfk_cfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1);
  (`fetch.wait.max.ms;`10)
  );
producer:.kafka.newProducer[kfk_cfg; 5000i]

topic1:.kafka.newTopic[producer;`test1;()!()]
topic2:.kafka.newTopic[producer;`test2;()!()]

.z.ts:{
  n+:1;topic:$[n mod 2;topic1;topic2];
  .kafka.publish[topic;.kafka.PARTITION_UA;string x;""];
  .kafka.publishWithHeaders[producer; topic; 1i; "locusts"; ""; `header1`header2!("firmament"; "divided")];
  }

-1 "Publishing on topics:", string[.kafka.getTopicName topic1], ", ", string[.kafka.getTopicName topic2];
.kafka.publish[;.kafka.PARTITION_UA; string .z.p; ""] each (topic1; topic2);

-1 "Published one message for each topic";
producer_meta:.kafka.getBrokerTopicConfig[producer];

show producer_meta `topics;
-1 "Set timer with \\t 500 to publish a message each second to each topic.";

