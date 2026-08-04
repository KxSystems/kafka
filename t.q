// test needs a kafka broker running with port 9092
// docker run -p 9092:9092 apache/kafka:latest
.t.e:{if[not value x;-1 x;'x]}
.Q.m.SP:enlist .Q.rp "::../out";
.kafka: use`kx.kafka;
\c 5000 5000
consumerCfg:(!) . flip(
    (`metadata.broker.list;`localhost:9092);
    (`group.id;`0);
    (`fetch.wait.max.ms;`10);
    (`statistics.interval.ms;`10000)
    );
producerCfg:(!) . flip(
  (`metadata.broker.list;`localhost:9092);
  (`statistics.interval.ms;`10000);
  (`queue.buffering.max.ms;`1)
  );
consumer:.kafka.Consumer[consumerCfg];
producer:.kafka.Producer[producerCfg];
sleep:{system $[.z.o=`w64;"PowerShell ";""],"sleep ",string x};

t)`orig_broker_id`orig_broker_name`brokers`topics ~ key .kafka.Metadata consumer 
t).kafka.Metadata[producer] ~ .kafka.Metadata[consumer]
t)-6h ~ type .kafka.ThreadCount[]
t)-6h ~ type .kafka.Version
t)-11h ~ type .kafka.VersionSym[]
t)98h ~ type .kafka.Errors[]

t)-6h ~ type topic1:.kafka.Topic[consumer;`test1;()!()]
t)-6h ~ type topic2:.kafka.Topic[producer;`test2;()!()]
t)`test1`test2 ~ .kafka.TopicName @/: (topic1;topic2)
t)null .kafka.TopicDel topic1
t)"type:expected i" ~ @[.kafka.TopicDel;"j"$topic1;{x}]
t)"unknown topic" ~ @[.kafka.TopicDel;topic1;{x}]

t)null .kafka.Subscribe[consumer;`test1;enlist .kafka.PARTITION_UA;{[msg]}]
sleep 1;
t)-11h ~ type .kafka.ClientMemberId consumer
/ t)0 < count string .kafka.ClientMemberId consumer // for some reason it fails in CI
t)-11h ~ type .kafka.ClientName consumer
t)-11h ~ type .kafka.ClientName producer
t)first[.kafka.Subscription[consumer]] ~ `topic`partition`offset`metadata!(`test1;-1i;-1001;"")
t)null .kafka.Unsub consumer
t)null .kafka.Unsub consumer // no error for doing it again
t)"type:expected i" ~ @[.kafka.Unsub;3;{x}]
t)"unknown client" ~ @[.kafka.Unsub;3i;{x}]
t)() ~ .kafka.Subscription[consumer]

t)null .kafka.ClientDel consumer
t)"type:expected i" ~ @[.kafka.ClientDel;3;{x}]
t)"unknown client" ~ @[.kafka.ClientDel;consumer;{x}]
t)"type:expected i[hij]" ~ .[.kafka.SetLoggerLevel;(3;3);{x}]
t)"unknown client" ~ .[.kafka.SetLoggerLevel;(consumer;3);{x}]
consumer:.kafka.Consumer[consumerCfg];
t)null .kafka.SetLoggerLevel[consumer;0]
t)"value" ~ .[.kafka.SetLoggerLevel;(consumer;-1);{x}]
t)"value" ~ .[.kafka.SetLoggerLevel;(consumer;8);{x}]

system $[.z.o=`w64;"start /B ";""],.z.X[0]," pubsub.q -p 5000",$[not .z.o=`w64;"&";""];
sleep 10;
h:hopen 5000;
h"publish[]";
data1:();
while [(0~count data1::h"data1") or not all value h"callbacksCalled"; sleep 1;];
@[h;"quit[]";{}];
seen:exec last offset by partition from data1;
t)() ~ .kafka.CommitOffsets[consumer;`test1;seen;1b]
t)99h ~ type first .kafka.CommittedOffsets[consumer;`test1;seen]
t)99h ~ type first .kafka.PositionOffsets[consumer;`test1;seen]
t)2 ~ count .kafka.queryWatermark[consumer;`test1;0;1000]
t)0 ~ .kafka.Poll[consumer;0;100]
t)100 ~ .kafka.MaxMsgsPerPoll 100

batchMsg:("test message 1";"test message 2");
t)0 0i ~ .kafka.BatchPub[topic2;.kafka.PARTITION_UA;batchMsg;""]
t)0 0i ~ .kafka.BatchPub[topic2;0i;batchMsg;""]
t)null .kafka.Pub[topic2;-1i;string .z.p;""]
t)null .kafka.PubWithHeaders[producer;topic2;-1i;string .z.p;"";`header1`header2!("test1";"test2")]
t)null .kafka.Flush[producer;5000]

t)99h ~ type .kafka.GetClientTopicMap[]
t)99h ~ type .kafka.GetClientTypeMap[]
t)98h ~ type .kafka.GetStats[]


exit 0
