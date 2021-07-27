//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @file controller.q
* @fileoverview
* Create a barrier by becoming a broker of executing instruction between producer and consumer.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Initial Setting                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\c 50 200
\l test_helper_function.q

// Set port 8888 by default
if[not system "p"; system "p 8888"];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Global Variable                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Socket of a process waiting a response.
* @note Situation where two clients are waiting cannot happen.
\
REQUESTER_SOCKET: (::);

/
* @brief Socket of a process under bondage.
\
BONDAGED_SOCKET: (::);

/
* @brief Name of the test examined at present.
\
CURRENT_TEST_ITEM: (::);

/
* @brief Expected result of the test examined at present.
\
CURRENT_EXPECTED_RESULT: (::);

/
* @brief Dictionary of client sockets.
\
CLIENTS: enlist[`]!enlist[(::)];

/
* @brief Process IDs of clients.
\
PIDS: `int$();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.z.pw:{[username;password]
  // Register client
  CLIENTS[username]: .z.w;
  1b
 };

shutdown:{
	-1 "Test completed";
  .test.DISPLAY_RESULT[];
  system each "kill -9 ",/: string PIDS;
  exit 0;
 };

.z.ts:{shutdown[]};

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Make the caller wait.
\
.control.barrier:{
  // Store the client socket and block it.
  BONDAGED_SOCKET:: .z.w;
  -30!(::);
 };

/
* @brief Release another client from waiting status.
* @return
* - true: Yielded a client.
* - false: There was not a waiting socket.
\
.control.yield_another:{
  $[(::) ~ BONDAGED_SOCKET;
    0b;
    [
      -30!(BONDAGED_SOCKET; 0b; ::);
      BONDAGED_SOCKET:: (::);
      1b
    ]
  ]
 };

/
* @brief Receive a request and deligate to another client while delivering the
*  target from the bondage.
* @param function {symbol}: Name of a function.
* @param arguments {compound list}: Arguments passed the function.
* @param item {string}: Test item. 
\
.control.deligate:{[function;arguments;item;expected]
  // Store current test information
  CURRENT_TEST_ITEM:: item;
  CURRENT_EXPECTED_RESULT:: expected;

  1 "Test | ", CURRENT_TEST_ITEM, " ... ";
  -30!(::);
  // Store the client socket
  REQUESTER_SOCKET:: .z.w;
  // Deliver the bound client.
  -30!(BONDAGED_SOCKET; 0b; ::);
  // Send a request from another client.
  neg[BONDAGED_SOCKET] (function; arguments);
 };

/
* @brief Return an answer from the caller to the another waiting client.
* @param result 
* - string: Error message in case of an error.
* - any: Result of a remote function call.
* @param is_error {bool}: Flag of execution error.
\
.control.return:{[result;is_error]
  .test.ASSERT_EQ[CURRENT_TEST_ITEM; actual; CURRENT_EXPECTED_RESULT];
  -30!(REQUESTER_SOCKET; is_error; result);
 };

/
* @brief Receive two values and test if they are equal and then score it.
* @param function {symbol}: Name of a function.
* @param arguments {compound list}: Arguments passed the function.
* @param item {string}: Test item. 
\
.control.submit_test:{[item;actual;expected]
  1 "Test | ", item, " ... ";
  .test.ASSERT_EQ[item; actual; expected];
 };

/
* @brief Receive a process ID and start a timer to shutdown if both clients reached to this prcoess.
* @param process_id {int}: Porcess ID of a client.
\
.control.finish:{[process_id]
  PIDS,: process_id;
  if[2 = count PIDS; system "t 3000"];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Start Process                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

commandline_args: " " sv {[k;v] "-", " " sv (string[k]; v)} ./: ( /
    (`confluenthost; "localhost");
    (`brokerport; "9092");
    (`schemaregistryport; "8081");
    (`controlport; string[system "p"])
  );

system "q test_producer.q ", commandline_args, ":producer:";
system "q test_consumer.q ", commandline_args, ":consumer:";
