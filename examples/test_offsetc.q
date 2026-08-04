.Q.m.SP:enlist .Q.rp "::../../out";
.kafka:use`kafka;

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit;`false);
    (`enable.auto.offset.store;`false)
    );
client:.kafka.Consumer[kfk_cfg];

// Topics to be published to
topic1:`test1
topic2:`test2
data:();

// Default callback function overwritten for managing of consumption from all topics
.kafka.SetTopicCb [`;{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,:enlist msg;}]
// Define Offset callback functionality
.kafka.SetOffsetCb[{[cid;err;offsets]show (cid;err;offsets);}]

// Subscribe to relevant topics from a defined client
.kafka.Sub[client;(topic1;topic2);(1#0i)!1#.kafka.OFFSET.END]

strt:.z.t
// The following example has been augmented to display and commit offsets for each of
// the available topics every 10 seconds
\t 5000
.z.ts:{n+:1;commit_topic:$[n mod 2;topic1;topic2];
  if[(5000<"i"$.z.t-strt)&1<count data;
    -1 "\nPublishing information from topic :",string commit_topic;
    show seen:exec 1+last offset by partition from data where topic=commit_topic;
    show "Position:";
    show .kafka.PositionOffsets[client;commit_topic;seen];
    show "Before commited:";
    show .kafka.CommittedOffsets[client;commit_topic;seen];
    .kafka.CommitOffsets[client;commit_topic;seen;0b];
    show "After commited:";
    show .kafka.CommittedOffsets[client;commit_topic;seen];]
  }
