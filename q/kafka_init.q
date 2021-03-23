//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_init.q
// @fileoverview
// Define kafka interface initiaizer.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind variable
// @category Global Variable
// @brief Tracked version of loaded kafkakdb.so. This is a relative versioning to
//  the initial loading to the q prcoess.
.kafka.LOADING_VERSION: 0;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Interface                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind function
// @category Initialization
// @brief Safely unhook sockets and store them for reloading a library.
.kafka.stash_sockets:LIBPATH_ (`stash_sockets; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind function
// @category Initiallization
// @brief Initialize internal state of interface.
// @note
// Replacement of `.kfk.Init`.
.kafka.init:LIBPATH_ (`init; 1);

// @kind function
// @category Initialization
// @brief Reload shared library.
.kafka.reload:{[]
  .kafka.LOADING_VERSION+:1;
  // Unsubscribe.
  .kafka.deleteClient each key .kafka.CLIENT_TYPE_MAP;
  // Stash spair.
  sockets: .kafka.stash_sockets[];
  // Load shared library.
  .kafka.newClient_impl:LIBPATH_ (`new_client; 3);
  .kafka.deleteClient_impl:LIBPATH_ (`delete_client;1);
  .kafka.manualPoll:LIBPATH_ (`manual_poll; 3);
  .kafka.setMaximumNumberOfPolling:LIBPATH_ (`set_maximum_number_of_polling; 1);
  .kafka.getClientName:LIBPATH_ (`get_client_name; 1);
  .kafka.setLogLevel:LIBPATH_ (`set_log_level; 2);
  .kafka.getOutQueueLength:LIBPATH_ (`get_out_queue_length; 1);
  .kafka.assignNewTopicPartition_impl:LIBPATH_ (`assign_new_topic_partition; 1);
  .kafka.addTopicPartitionToAssignment_impl:LIBPATH_ (`add_topic_partition; 2);
  .kafka.deleteTopicPartitionFromAssignment_impl:LIBPATH_ (`delete_topic_partition; 2);
  .kafka.getPrevailingOffsets_impl:LIBPATH_ (`get_prevailing_offsets; 3);
  .kafka.getCommittedOffsetsForTopicPartition_impl:LIBPATH_ (`get_committed_offsets_for_topic_partition; 3);
  .kafka.getEarliestOffsetsForTimes_impl:LIBPATH_ (`get_earliest_offsets_for_times; 4);
  .kafka.assignNewOffsetsToTopicPartition:LIBPATH_        (`assign_new_offsets_to_topic_partition; 3);
  .kafka.commitOffsetsToTopicPartition:LIBPATH_ (`commit_offsets_to_topic_partition; 4);
  .kafka.getCurrentAssignment:LIBPATH_ (`get_current_assignment; 1);
  .kafka.getBrokerTopicConfig:LIBPATH_ (`get_broker_topic_config; 2);
  .kafka.unsubscribe_impl:LIBPATH_ (`unsubscribe; 1);
  .kafka.getConsumerGroupMemberID:LIBPATH_     (`get_consumer_group_member_id; 1);
  .kafka.getCurrentSubscription:LIBPATH_ (`get_current_subscription; 1);
  .kafka.subscribe:LIBPATH_ (`subscribe; 2);
  .kafka.getKafkaThreadCount:LIBPATH_ (`get_kafka_thread_count; 1);
  .kafka.version:LIBPATH_ (`version; 1);
  .kafka.versionString:LIBPATH_ (`version_string; 1);
  .kafka.errorDescriptionTable:LIBPATH_ (`kafka_error_description_table; 1);
  .kafka.publishBatch_impl:LIBPATH_    (`publish_batch; 4);
  .kafka.flushProducerHandle:LIBPATH_ (`flush_producer_handle; 2);
  .kafka.publishWithHeaders:LIBPATH_   (`publish_with_headers; 6);
  .kafka.publish:LIBPATH_ (`publish; 4);
  .kafka.newTopic_impl:LIBPATH_ (`new_topic; 3);
  .kafka.deleteTopic_impl:LIBPATH_ (`delete_topic; 1);
  .kafka.getTopicName:LIBPATH_ (`get_topic_name; 1);
  .kafka.init:LIBPATH_ (`init; 1);
  .kafka.stash_sockets:LIBPATH_ (`stash_sockets; 1);
  // Execute `init` with the stashed sockets.
  .kafka.init[sockets]
 }