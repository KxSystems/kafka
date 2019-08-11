\l ../kfk.q

kfk_cfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`queue.buffering.max.ms;`1);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000);
    (`enable.auto.commit;`false);
    (`enable.auto.offset.store;`false)
    );
client:.kfk.Consumer[kfk_cfg];
TOPIC:`test
data:();
.kfk.consumecb:{[msg]
    msg[`data]:"c"$msg[`data];
    msg[`rcvtime]:.z.p;
    data,::enlist msg;}
.kfk.offsetcb:{[cid;err;offsets]show (cid;err;offsets);}


show .kfk.AssignOffsets[client;TOPIC;(1#0i)!1#.kfk.OFFSET.END]     // start replaying from the end
.kfk.Sub[client;TOPIC;(1#0i)!1#.kfk.OFFSET.END];


strt:.z.t
\t 5000
.z.ts:{
  if[(5000<"i"$.z.t-strt)&1<count data;
  seen:exec last offset by partition from data;
  show "Position:";
  show .kfk.PositionOffsets[client;TOPIC;seen];
  show "Before commited:";
  show .kfk.CommittedOffsets[client;TOPIC;seen];
  .kfk.CommitOffsets[client;TOPIC;seen;0b];  // commit whatever is storred
  show "After commited:";
  show .kfk.CommittedOffsets[client;TOPIC;seen];]
  }
