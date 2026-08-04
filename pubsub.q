.Q.m.SP:enlist .Q.rp "::../out";
.kafka: use`kx.kafka;
sleep:{system $[.z.o=`w64;"PowerShell ";""],"sleep ",string x};

callbacksCalled:`errcb`defaulterrcb`logcb`statcb`deliverycb`offsetcb!6#0b;

consumerCfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`1000);
    (`statistics.interval.ms;`2000)
    );
producerCfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`2000);
  (`queue.buffering.max.ms;`10)
  );
.kafka.SetLogCb[{[level;fac;buf] callbacksCalled[`logcb]:1b}];
.kafka.SetStatCb[{[x] callbacksCalled[`statcb]:1b}];
.kafka.SetDeliveryCb[{[cid;msg] callbacksCalled[`deliverycb]:1b}];
.kafka.SetOffsetCb[{[cid;err;offsets] callbacksCalled[`offsetcb]:1b;}]
consumer:.kafka.Consumer[consumerCfg];
consumer2:.kafka.Consumer[`metadata.broker.list`group.id!`foobar`0];
consumer3:.kafka.Consumer[`metadata.broker.list`group.id!`foobar`0];
.kafka.SetPerClientErrorCb[`;{[cid;errInt;reason] callbacksCalled[`defaulterrcb]:1b}];
.kafka.SetPerClientErrorCb[consumer3;{[cid;errInt;reason] callbacksCalled[`errcb]:1b}];
producer:.kafka.Producer[producerCfg];
topic1:.kafka.Topic[producer;`test1;()!()];
sleep 2; // wait for topic to be created
data1:();
.kafka.Subscribe[consumer;.kafka.TopicName topic1;enlist .kafka.PARTITION_UA;{[msg]0N!msg;{0N!x} each msg;0N!msg[`data];msg[`data]:"c"$msg[`data];data1,:enlist msg;0N!"pubsub: data arrived",string count data1}];

publish: {
  0N!"publish called";
  batchMsg:("test message 1";"test message 2");
  .kafka.BatchPub[topic1;.kafka.PARTITION_UA;batchMsg;""];
  .kafka.BatchPub[topic1;0i;batchMsg;""];
  .kafka.Pub[topic1;-1i;string .z.p;""];
  .kafka.PubWithHeaders[producer;topic1;-1i;string .z.p;"";`header1`header2!("test1";"test2")];
  0N!"current queue:", string .kafka.OutQLen producer;
  .kafka.Flush[producer;10000];
  0N!"Finished flush";
  }

quit: {
  .kafka.Unsub consumer;
  .kafka.TopicDel topic1;
  .kafka.ClientDel consumer;
  .kafka.ClientDel producer;
  sleep 0.5;
  exit 0
  }
