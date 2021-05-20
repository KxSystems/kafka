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

adjusted_l:{[file]
  loaded: @[system; "l ", string file; `LOAD_ERROR];
  if[loaded ~ `LOAD_ERROR; system "l q/", string file];
 };


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind variable
// @category Configuration
// @brief Identifier if user is using deprecated functions.
.kafka.USE_DEPRECATED: 1b;

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

adjusted_l `kafka_client.q;
adjusted_l `kafka_configuration.q;
adjusted_l `kafka_consumer.q;
adjusted_l `kafka_info.q;
adjusted_l `kafka_init.q;
adjusted_l `kafka_producer.q;
adjusted_l `kafka_topic.q;
adjusted_l `kafka_deprecated.q;
adjusted_l `transformer.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initialize State                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.kfk.Init[];
