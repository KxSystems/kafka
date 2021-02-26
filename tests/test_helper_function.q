// test_helper_function.q

// Open namespace test
\d .test

// --------------- TEST GLOBALS --------------- //

// Define enum representing status of executing a function
EXECUTION_STATUS__:`Ok`Error;
EXECUTION_ERROR__:`.test.EXECUTION_STATUS__$`Error;
EXECUTION_OK__:`.test.EXECUTION_STATUS__$`Ok;

PASSED__: 0;
FAILED__: 0;

/
* @brief Check if two objects are identical.
* @param lhs: left hand side of comparison.
* @param rhs: left hand side of comparison.
\
ASSERT_EQ:{[lhs; rhs]
  result:lhs ~ rhs;
  $[result;
    [
      PASSED__+:1;
      (::)
    ];
    [
      FAILED__+:1;
      message:"assertion failed.\n\tleft:", (-3!lhs), "\n\tright:", -3!rhs;
      -2 message;
    ]
  ]
 }

/
* @brief Check if two objects are alike.
* @param lhs: left hand side of comparison.
* @param rhs: left hand side of comparison.
\
ASSERT_LIKE:{[lhs; rhs]
  result:lhs like rhs;
  $[result;
    [
      PASSED__+:1;
      (::)
    ];
    [
      FAILED__+:1;
      message:"assertion failed.\n\tleft:", (-3!lhs), "\n\tright:", -3!rhs;
      -2 message;
    ]
  ]
 }

/
* @brief Check if two objects are identical.
* @param lhs: left hand side of comparison.
* @param rhs: left hand side of comparison.
* @param like_cmp: Compare with `like`.
\
ASSERT:{[expr]
  $[expr;
    [
      PASSED__+:1;
      (::)
    ];
    [
      FAILED__+:1;
      -2 "assertion failed.\n\tleft:1b\n\tright:0b";
    ]
  ]
 }

/
* @brief Check if execution fails and teh returned error matches a specified message
* @param func: interface function to apply
* @param args: list of arguments to pass to the function
* @param errkind: string error kind message to expect. ex.) "Invalid scalar type"
\
ASSERT_ERROR:{[func; args; errkind]
  res:.[func; args; {[err] (EXECUTION_ERROR__; err)}];
  $[EXECUTION_ERROR__ ~ first res; 
    ASSERT_LIKE[res[1]; errkind,"*"];
    ASSERT[0b]
  ]
 }

DISPLAY_RESULT:{[]
  result:$[FAILED__; "FAILED"; "ok"];
  -1 "test result: ", result, ". ", string[PASSED__], " passed; ", string[FAILED__], " failed";
 }

// ------------------- END -------------------- //

// Close namespace
\d .