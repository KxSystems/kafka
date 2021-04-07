/
* @file void.q
* @overview
* Dummy entry q file which is run at the start up of a container. User can replace
*  this file with a q script which loads `lfl.q` or `kafka.q` with `\l kafka.q` or
*  `\l kfk.q`.
\

// \l kfk.q if you are using old functions.
\l kafka.q
