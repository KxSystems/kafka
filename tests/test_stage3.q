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

// Get current client type map
current_client_topic_map: .kafka.CLIENT_TOPIC_MAP;

.test.ASSERT_EQ["unsubscibe consumer"; .kafka.CLIENT_TOPIC_MAP; consumer _ current_client_topic_map]

// Unsubscribe
.kafka.unsubscribe[consumer];

// Get current client type map
current_client_map: .kafka.CLIENT_TYPE_MAP;

// Delete consumer
.kafka.deleteClient[consumer];

.test.ASSERT_EQ["delete consumer"; .kafka.CLIENT_TYPE_MAP; consumer _ .kafka.CLIENT_TYPE_MAP]

// Cannot delete because producer is using the topic.
.test.ASSERT_ERROR["delete topic1"; .kafka.deleteTopic; topic1; "someone is subscribing"]

// Get current client type map
current_client_topic_map: .kafka.CLIENT_TOPIC_MAP;

// Delete producer
.kafka.deleteClient[producer];

.test.ASSERT_EQ["delete producer"; .kafka.CLIENT_TOPIC_MAP; producer _ current_client_topic_map]

// Delete topic1
.kafka.deleteTopic[topic1];
// Delete topic2
.kafka.deleteTopic[topic2];

.test.DISPLAY_RESULT[];