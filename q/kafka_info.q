//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_info.q
// @fileoverview
// Define kafka information interface.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind function
// @category Information
// @brief Returns the number of threads currently being used by librdkafka.
// @return The number of thread used by rdkafka.
// @note
// Replacement of `.kfk.Threadcount`.
.kafka.getKafkaThreadCount:LIBPATH_ (`get_kafka_thread_count; 1);

// @kind function
// @category Information
// @brief Get rdkafka version.
// @return
// - int: Version of rdkafka.
// @note
// Replacement of `.kfk.Version`.
.kafka.version:LIBPATH_ (`version; 1);

// @kind function
// @category Information
// @brief Returns the human readable librdkafka version.
// @return
// - string: String version of librdkafka.
// @note
// replacement of `.kfk.VersionSym`.
.kafka.versionString:LIBPATH_ (`version_string; 1);

// @kind function
// @category Information
// @brief Display error description for each error code.
// @return
// - table: Error description table of librdkafka.
// @note
// Replacement of `.kfk.ExportErr`.
.kafka.errorDescriptionTable:LIBPATH_ (`kafka_error_description_table; 1);
