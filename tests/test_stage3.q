//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file test_stage3.q
* @fileoverview
* Conduct tests of cleanup.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                          Tests                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Unsubscribe
.kafka.unsubscribe[consumer];

.test.ASSERT_EQ["unsubscribe - subscription"; .kafka.getCurrentSubscription consumer; ()]
.test.ASSERT_EQ["unsubscribe - callback"; count .kafka.CONSUME_TOPIC_CALLBACK_PER_CONSUMER consumer; 0]

// Get current client type map
current_client_map: .kafka.CLIENT_TYPE_MAP;

// Delete consumer
.kafka.deleteClient[consumer];

.test.ASSERT_EQ["delete consumer"; .kafka.CLIENT_TYPE_MAP; consumer _ .kafka.CLIENT_TYPE_MAP]
// Map was not affected
.test.ASSERT_EQ["delete consumer - callback"; count .kafka.ERROR_CALLBACK_PER_CLIENT; 2]

// Get current client type map
current_client_topic_map: .kafka.PRODUCER_TOPIC_MAP;

// Delete topic1
.kafka.deleteTopic[topic1];

.test.ASSERT_EQ["delete topic1"; .kafka.PRODUCER_TOPIC_MAP[producer]; enlist topic2]

// Delete producer
.kafka.deleteClient[producer];

.test.ASSERT_EQ["delete producer"; .kafka.PRODUCER_TOPIC_MAP; producer _ current_client_topic_map]
.test.ASSERT_EQ["delete producer - callback"; count .kafka.ERROR_CALLBACK_PER_CLIENT; 1]

// Delete topic2
.kafka.deleteTopic[topic2];

.test.DISPLAY_RESULT[];