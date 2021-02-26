//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_topic.q
// @fileoverview
// Define kafka topic interfaces.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind variable
// @category Topic
// @brief Mapping between client and the topics
.kafka.CLIENT_TOPIC_MAP:(`int$())!();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind function
// @category Topic
// @brief Create a new topic.
// @param client_idx {int}: index of client in `CLIENTS`.
// @param topic {symbol}: New topic to create.
// @param config {dictionary}: Dictionary storing configuration of the new topic.
// - key {symbol}: Key of the configuration.
// - value {symbol}: Value of the configuration.
// @return
// - int: Topic handle assigned by kafka.
.kafka.newTopic_impl:LIBPATH_ (`new_topic; 3);

// @private
// @kind function
// @category Topic
// @brief Delete the given topic.
// @param topic_idx {int}: Index of topic in `TOPICS`.
// @note
// Replacement of `.kfk.TopicDel`
.kafka.deleteTopic_impl:LIBPATH_ (`delete_topic; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Setting %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @kind function
// @category Topic
// @brief Get a name of topic from topic index.
// @param topic_idx {int}: Index of topic in `TOPICS`.
// @return
// - symbol: Topic name.
// @note
// Replacement of `.kfk.TopicName`
.kafka.getTopicName:LIBPATH_ (`get_topic_name; 1);

//%% Create/Delete %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @kind function
// @category Create/Delete
// @brief Create a new topic and tie up with a given client by `.kafka.CLIENT_TOPIC_MAP`.
// @param client_idx {int}: index of client in `CLIENTS`.
// @param topic {symbol}: New topic to create.
// @param config dictionary}: Dictionary storing configuration of the new topic.
// - key {symbol}: Key of the configuration.
// - value {symbol}: Value of the configuration.
// @return
// - int: Topic handle assigned by kafka.
// @note
// Replacement of `.kfk.Topic`
.kafka.newTopic:{[client_idx;topic;config]
  topic:.kafka.newTopic_impl[client_idx; topic; config];
  .kafka.CLIENT_TOPIC_MAP[client_idx],: topic;
  topic
 };
