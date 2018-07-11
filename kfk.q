\d .kfk
LIBPATH:`:libkfk 2:
funcs:(
		// .kfk.Client[client_type(.kfk.PRODUCER or .kfk.CONSUMER);`config1`config2!`val1`val2]
		// return int32 client_id
	(`kfkClient;2);
		// .kfk.ClientDel[client_id]
	(`kfkClientDel;1);
		// .kfk.ClientName[client_id]
	(`kfkClientName;1);
		// .kfk.ClientMemberId[client_id]
	(`kfkClientMemberId;1);
		// .kfk.Topic[client_id;`topicname;`topiccfg1`topiccfg2!`val1`val2] -> topic_id
	(`kfkTopic;3);
		// .kfk.TopicDel[topic_id]
	(`kfkTopicDel;1);
		// .kfk.TopicName[topic_id]
	(`kfkTopicName;1);
		// .kfk.Metadata[client_id]
	(`kfkMetadata;1);
	// PRODUCER API
		// .kfk.Pub[topic_id;partid;data;key]
	(`kfkPub;4);
		// .kfk.OutQLen[client_id]
	(`kfkOutQLen;1);
	// CONSUMER API
		// .kfk.Sub[client_id;`topicname;partition_list]
	(`kfkSub;3);
		// .kfk.Unsub[client_id]
	(`kfkUnsub;1);
		// .kfk.Subscription[client_id]
	(`kfkSubscription;1);
		// .kfk.Poll[client_id;timeout;max_messages]
	(`kfkPoll;3);
		// .kfk.Version[]
	(`kfkVersion;1);
		// .kfk.ExportErr[]
	(`kfkExportErr;1)
	);


// binding functions from dictionary funcs using rule
// kfk<Name> -> .kfk.<Name>
.kfk,:(`$3_'string funcs[;0])!LIBPATH@/:funcs

// Current version of librdkafka
Version:Version[];

// Table with all errors return by kafka with codes and description
Errors:ExportErr[];

// Unassigned partition.
// The unassigned partition is used by the producer API for messages
// that should be partitioned using the configured or default partitioner.
PARTITION_UA:-1i

// Producer client code
PRODUCER:"p"
Producer:Client[PRODUCER;]

// Consumer client code
CONSUMER:"c"
Consumer:Client[CONSUMER;]

// table with kafka statistics
stats:() 	

// CALLBACKS -  should not be deleted or renamed and be present in .kfk namespace

// statistics provided by kafka about current state
statcb:{[j]
	s:.j.k j;if[all `ts`time in key s;s[`ts]:-10957D+`timestamp$s[`ts]*1e3;s[`time]:-10957D+`timestamp$1e9*s[`time]];
	.kfk.stats,::enlist s;
	delete from `.kfk.stats where i<count[.kfk.stats]-100;}

// logging callback
logcb:{[level;fac;buf] show -3!(level;fac;buf);}

// delivery callback
drcb:{[msg]}

// Main callback for consuming messages(including errors)
consumecb:{[msg]}

\d .
