//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kfk.q
// @fileoverview
// Entry point of kafkakdb library. This file is provided to support deprecated (named) functions.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

LIBPATH_:$[
  (`kafkakdb.so in key hsym `$getenv[`QHOME], (1#string .z.o), "64") or `kafkakdb.so in key hsym `$getenv `LD_LIBRARY_PATH;
  // Exist under QHOME/[os]64 or LD_LIBRARY_PATH
  `:kafkakdb 2:;
  `kafkakdb.so in key `:clib;
  // Exist under clib.
  `:clib/kafkakdb 2:;
  // Default location
  `:kafkakdb 2:
 ];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind variable
// @category Configuration
// @brief Unassigned partition. The unassigned partition is used by the producer API for messages
//  that should be partitioned using the configured or default partitioner.
.kfk.PARTITION_UA:-1i;

// @kind variable
// @category Configuration
// @brief Start consuming from beginning of kafka partition queue: oldest message.
.kfk.OFFSET.BEGINNING:-2;

// @kind variable
// @category Configuration
// @brief Start consuming from end of kafka partition queue: next message.
.kfk.OFFSET.END:-1;

// @kind variable
// @category Configuration
// @brief Start consuming from offset retrieved from offset store.
.kfk.OFFSET.STORED:-1000;

// @kind variable
// @category Configuration
// @brief Invalid offset.
.kfk.OFFSET.INVALID:-1001;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Load Modules                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l kafka_client.q
\l kafka_configuration.q
\l kafka_consumer.q
\l kafka_info.q
\l kafka_init.q
\l kafka_producer.q
\l kafka_topic.q
\l kafka_deprecated.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initialize State                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.kfk.init[];
