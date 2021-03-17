// test_helper_function.q

// Open namespace test
\d .test

// --------------- TEST GLOBALS --------------- //

// Define enum representing status of executing a function
EXECUTION_STATUS__:`Ok`Error;
EXECUTION_ERROR__:`.test.EXECUTION_STATUS__$`Error;
EXECUTION_OK__:`.test.EXECUTION_STATUS__$`Ok;

// Counter of pass and failure.
PASSED__: 0;
FAILED__: 0;

// Table of test items.
MODULES__: flip `item`failed!"*b"$\:();

/
* @brief Check if two objects are identical.
* @param test_name {string}: Name of the test item.
* @param lhs: left hand side of comparison.
* @param rhs: left hand side of comparison.
\
ASSERT_EQ:{[test_name; lhs; rhs]
  if[not 10h ~ type test_name; '"test name must be string"];
  result:lhs ~ rhs;
  $[result;
    [
      PASSED__+:1;
      `.test.MODULES__ insert (enlist test_name; 0b); 
      (::)
    ];
    [
      FAILED__+:1;
      `.test.MODULES__ insert (enlist test_name; 1b); 
      message:"assertion failed.\n\tleft:", (-3!lhs), "\n\tright:", -3!rhs;
      -2 message;
    ]
  ]
 }

/
* @brief Check if two objects are alike.
* @param test_name {string}: Name of the test item.
* @param lhs {string|symbol}: left hand side of comparison.
* @param rhs {string}: left hand side of comparison.
\
ASSERT_LIKE:{[test_name; lhs; rhs]
  if[not 10h ~ type test_name; '"test name must be string"];
  result:lhs like rhs;
  $[result;
    [
      PASSED__+:1;
      `.test.MODULES__ insert (enlist test_name; 0b); 
      (::)
    ];
    [
      FAILED__+:1;
      `.test.MODULES__ insert (enlist test_name; 1b); 
      message:"assertion failed.\n\tleft:", (-3!lhs), "\n\tright:", -3!rhs;
      -2 message;
    ]
  ]
 }

/
* @brief Check if two objects are identical.
* @param test_name {string}: Name of the test item.
* @param expr {bool}: Give `1b` for expected result.
\
ASSERT:{[test_name;expr]
  if[not 10h ~ type test_name; '"test name must be string"];
  $[expr;
    [
      PASSED__+:1;
      `.test.MODULES__ insert (enlist test_name; 0b);
      (::)
    ];
    [
      FAILED__+:1;
      `.test.MODULES__ insert (enlist test_name; 1b);
      -2 "assertion failed.\n\tleft:1b\n\tright:0b";
    ]
  ]
 }

/
* @brief Check if execution fails and teh returned error matches a specified message.
* @param test_name {string}: Name of the test item.
* @param func: interface function to apply
* @param args: list of arguments to pass to the function
* @param errkind {string}: string error kind message to expect. ex.) "Invalid scalar type"
\
ASSERT_ERROR:{[test_name;func;args;errkind]
  res:.[func; args; {[err] (EXECUTION_ERROR__; err)}];
  $[any EXECUTION_ERROR__ ~/: res; 
    ASSERT_LIKE[test_name; res[1]; errkind,"*"];
    ASSERT[test_name; 0b]
  ]
 }

DISPLAY_RESULT:{[]
  result:$[FAILED__; "FAILED"; "ok"];
  if[FAILED__; show `failed xcol select item from MODULES__ where failed];
  -1 "test result: ", result, ". ", string[PASSED__], " passed; ", string[FAILED__], " failed";
 }

// ------------------- END -------------------- //

// Close namespace
\d .