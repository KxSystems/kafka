//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file deprecated_consumer.q
// @fileoverview
// Example consumer for deprecated version. This version does not should not be linked to transformer.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Library                      //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l ../q/kfk.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`broker:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit; `false);
    (`api.version.request; `true)
  );

// Table to store received data.
data1:();
data2:();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 25 200

// Create a new consumer
consumer:.kfk.Consumer[kfk_cfg];

// Topics to subscribe to
topic1:`test1;
topic2:`test2;

// Define topic callbacks for individual topic subscriptions `topic1 and `topic2
topcb1:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.p;
  data1,::enlist msg;
  .kfk.CommitOffsets[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

topcb2:{[msg]
  msg[`data]:"c"$msg[`data];
  msg[`rcvtime]:.z.t;
  data2,::enlist msg;
  .kfk.CommitOffsets[consumer; msg `topic; enlist[msg `partition]!enlist msg[`offset]; 1b];
 };

// Callback for committing offset
.kfk.offsetcb:{[consumer_idx;error;offsets]
  $[
    error ~ "Success";
    -1 "committed:", .Q.s1 offsets;
    -2 "commit error: ", error
  ];
 };

// Subscribe to topic1 and topic2 with different callbacks from a single client
.kfk.Subscribe[consumer; topic1; enlist .kfk.PARTITION_UA; topcb1]
.kfk.Subscribe[consumer; topic2; enlist .kfk.PARTITION_UA; topcb2]

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

consumer_meta:.kfk.Metadata[consumer];
show consumer_meta`topics;
