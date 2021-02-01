//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_init.q
// @fileoverview
// Define kafka interface initiaizer.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind variable
// @category Initiallization
// @brief Initialize internal state of interface.
// @note
// Replacement of `.kfk.Init`.
.kafka.init:LIBPATH_ (`init; 1);
