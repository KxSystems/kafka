//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_stage2.q
* @fileoverview
* Conduct tests from the stage where subscription is completed.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Get current number of rows.
current_offset_1:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]
current_offset_2:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic2; enlist 0i]

// Publish message
.kafka.publish[topic1; 0i; "Hello"; "greeting1"];
.kafka.publish[topic2; 0i; "Hello"; "greeting2"];
.kafka.publish[topic1; 0i; "Hello2"; "greeting1"];

// Flush the handle
.kafka.flushProducerHandle[producer; 1000];

// Ensure time elapses for 60 seconds.
.test.ASSERT_EQ["get earliest offset since 1 minute ago for topic1"; last exec offset from .kafka.getEarliestOffsetsForTimes[consumer; `topic1; enlist[0i]!enlist .z.p-0D00:01:00.000000000; 1000]; current_offset_1];
.test.ASSERT_EQ["get earliest offset since 1 minute ago for topic2"; last exec offset from .kafka.getEarliestOffsetsForTimes[consumer; `topic2; enlist[0i]!enlist .z.p-0D00:01:00.000000000; 1000]; current_offset_2];

.test.ASSERT_EQ["offset for topic1 after publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]) - current_offset_1; 2]
.test.ASSERT_EQ["offset for topic2 after publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic2; enlist 0i]) - current_offset_2; 1]

// Get current number of rows.
current_offset_1:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]
current_offset_2:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic2; enlist 0i]

// Get current table sizes.
current_num_rows_1: count consumer_table1;
current_num_rows_2: count consumer_table2;

// Assign new offset
.kafka.assignNewOffsetsToTopicPartition[consumer; `topic1; enlist[0i]!enlist 1];
.kafka.assignNewOffsetsToTopicPartition[consumer; `topic2; enlist[0i]!enlist 1];

// Ensure consumer received everything
//while[not 0 = .kafka.getOutQueueLength consumer; .kafka.manualPoll[consumer; 1000; 100]];

// Read 
.test.ASSERT_EQ["assign new offset for topic1 reloads messages til latest"; count[consumer_table1]-current_num_rows_1; current_offset_1]
.test.ASSERT_EQ["assign new offset for topic2 reloads messages til latest"; count[consumer_table2]-current_num_rows_2; current_offset_2]

// Get current number of rows.
current_offset_1:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]
current_offset_2:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic2; enlist 0i]

// Publish messages
.kafka.publishBatch[producer; topic1; 0i; ("batch hello"; "batch hello2"); ""];

// Flush the handle
.kafka.flushProducerHandle[producer; 1000];

// Somehow tis fails. Consumer does not receive the message though it receives messages for topic2.
// Probably this is related to the setting where producer sends to the consumer in the same q process.
// This works in the example separated producer and consumer.
.test.ASSERT_EQ["offset proceeds for topic 1 after batch publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]) - current_offset_1; 2]

// Publish messages
.kafka.publishBatch[producer; topic2; 0 0i; ("batch hello"; "batch hello2"); ""];

// Flush the handle
.kafka.flushProducerHandle[producer; 1000];

.test.ASSERT_EQ["offset proceeds for topic 2 after batch publish"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic2; enlist 0i]) - current_offset_2; 2]

current_offset_1:last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]

// Publish with headers.
.kafka.publishWithHeaders[producer; topic1; 0i; "locusts"; ""; `header1`header2!("firmament"; "divided")];

// Flush the handle
.kafka.flushProducerHandle[producer; 1000];

// Somehow tis fails. Consumer does not receive the message though it receives messages for topic2.
// Probably this is related to the setting where producer sends to the consumer in the same q process.
// This works in the example separated producer and consumer.
.test.ASSERT_EQ["offset proceeds for topic 1 after publish with headers"; (last exec offset from .kafka.getCommittedOffsetsForTopicPartition[consumer; `topic1; enlist 0i]) - current_offset_1; 1]

// Continue to test_stage3.q
// q)\l test_stage3.q
