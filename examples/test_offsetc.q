\l ../q/kafka.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`queue.buffering.max.ms;`1);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit;`false);
    (`enable.auto.offset.store;`false)
    );
consumer:.kafka.newConsumer[kfk_cfg];

// Topics to be published to
topic1:`test1
topic2:`test2
data:();

// Overwrite default offset callback functionality triggered by consumer-poll.
.kafka.offset_commit_cb:{[consumer_idx;err;offsets]
  show (consumer_idx;err;offsets);
 };

// Assign partitions to consume from specified offsets
show .kafka.assignNewOffsetsToTopicPartition[consumer; ; (1#0i)!1#.kafka.OFFSET_END] each (topic1; topic2);

// Subscribe to relevant topics from a defined client
.kafka.subscribe[consumer; ; (1#0i)!1#.kafka.OFFSET_END] each (topic1;topic2);

// Callback function for consumption from all topics
consume_callback:{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,::enlist msg;
 };

.kafka.registerConsumeTopicCallback[consumer; consume_callback] each (topic1;topic2);

start:.z.t;

// The following example has been augmented to display and commit offsets for each of
// the available topics every 10 seconds
.z.ts:{
  n+:1;
  topic:$[n mod 2; topic1; topic2];
  if[(5000 < "i"$.z.t-start) & 1 < count data;
    -1 "\nPublishing information from topic :",string topic;
    show seen:exec last offset by partition from data where topic=topic;
    
    show "Position:";
    show .kafka.setOffsetsToEnd[consumer; topic; seen];
    
    show "Before commited:";
    show .kafka.getCommittedOffsetsForTopicPartition[consumer; topic; seen];

    .kafka.commitNewOffsetsToTopicPartition[consumer; topic; seen; 0b];
    
    show "After commited:";
    show .kafka.getCommittedOffsetsForTopicPartition[consumer; topic; seen];]
 };

\t 5000