//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    File Decription                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @file kafka_schema_registry.q
// @fileoverview
// Define kafka schema registry interfaces.
// @note
// - These methods are dependent on `transformer.q`.
// - Schema should not evolve automatically. All schemas need to be stored
//  locally and the schemas will be retrieved when a producer creates a topic
//  or consumer subscribes to a topic.
// - Protobuf schema used for conversion directly on messages should be defined
//  one per file because it is the concept of conversion related to topic. Format
//  for the same topic must be unique.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind function
// @brief Remove comments and replace escape "\" with furher escape "\\\".
// @param path {string}: Path to a file to read.
// @return 
// - string: Processed file contents.
.kafka.process_file:{[path]
  text: read0 hsym `$path;
  // Remove lines which start from comment.
  text: text where {[line] not any line like/: ("//*"; "  //*")} each text;
  // Remove comment after an expression.
  text: {[line] line til count[line] ^ first ss[line; "//"]} each text;
  ssr[raze text; "\""; "\\\""]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Schema %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

// @kind function
// @category SchemaRegistry
// @brief Register a schema to Kafka schema registry.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param topic {symbol}:
// - non-null: Topic to which the schema is used.
// - null: Schema is not tied with topic, i.e., independently uploaded (ex. Protobuf schema has dependency).
// @param path {string}: Path to a schema file.
// @param schema_type_ {enum}: One of these value:
//  - .qtfm.JSON
//  - .qtfm.AVRO
//  - .qtfm.PROTOBUF
// @return 
// - long: Schema ID.
// @note The specified topic must exist on Confluent platform; otherwise an error
//   ```
//     "{\"error_code\":50001,\"message\":\"Register schema operation failed while writing to the Kafka store\"}"
//   ```
//  will be returned.
.kafka.registerSchema:{[host;port;topic;path;schema_type_]

  schema_type: $[
    schema_type_ ~ .qtfm.JSON; "JSON";
    schema_type_ ~ .qtfm.AVRO; "AVRO";
    schema_type_ ~ .qtfm.PROTOBUF; "PROTOBUF";
    // Other
    '"Unsupported format: ", last "$" vs .Q.s1 schema_type_
  ];

  subjects: $[null topic;
    last "/" vs path;
    string[topic], "-value"
  ];

  schema: .kafka.process_file[path];

  text: "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" ";
  text,: "--data '{\"schema\":\"", schema, "\", \"schemaType\": \"", schema_type, "\"}' ";
  // Schema is registered against topic
  text,: "http://", string[host], ":", string[port], "/subjects/", subjects, "/versions";
  
  result: .j.k first system text;
  $[`error_code in key result;
    // Error
    'result `message;
    // Globally unique ID of the new schema
    `long$result `id
  ]
 };

// @kind function
// @category SchemaRegistry
// @brief Retrieve a schema information from Kafka schema registry with a topic and a schema version.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param topic {symbol}: Topic to which the schema is used.
// @param version {symbol}: Version of the schema. Version number or `latest`.
// @return 
// - dictionary: Schehma information
//   - id {long}: Schema ID
//   - schemaType {enum}: Schema type
//   - schema {string}: Schema  
.kafka.getSchemaInfoByTopic:{[host;port;topic;version]
  text: "curl -H \"Accept: application/vnd.schemaregistry.v1+json\" ";
  text,: "http://", string[host], ":", string[port], "/subjects/", string[topic], "-value/versions/", string[version];

  result: .j.k first system text;
  $[`error_code in key result;
    // Error
    'result `message;
    // Schema ID, schema type and schema
    (@/)[`id`schemaType`schema # result; `id`schemaType; (`long$; {[schema_type] get `$".qtfm.", $["" ~ schema_type; "AVRO"; schema_type]})]
  ]
 };

// @kind function
// @category SchemaRegistry
// @brief Retrieve a schema from Kafka schema registry with a nique schema ID.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param schema_id {number}: Globally unique schema ID.
.kafka.getSchemaByID:{[host;port;schema_id]
  text: "curl -H \"Accept: application/vnd.schemaregistry.v1+json\" ";
  text,: "http://", string[host], ":", string[port], "/schemas/ids/", string[schema_id];

  result: .j.k first system text;
  $[`error_code in key result;
    // Error
    'result `message;
    // Schema
    result `schema
  ]
 };

// @kind function
// @category SchemaRegistry
// @brief Delete a schema from Kafka schema registry with a topic and a schema version.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param topic {symbol}: Topic to which the schema is used.
// @param version {symbol}: Version of the schema. Version number or `latest`.
// @return 
// - long: Deleted version.
// @note The schema ID increases every time you upload a new schema and it is not deletable from teh registry.
//  What you can do is to delete the registered schema information for a topic.
.kafka.deleteSchema:{[host;port;topic;version]
  text: "curl -X DELETE -H \"Accept: application/vnd.schemaregistry.v1+json\" ";
  text,: "http://", string[host], ":", string[port], "/subjects/", string[topic], "-value/versions/", string[version];

  result: .j.k first system text;
  $[not -9h ~ type result;
    // Error
    'result `message;
    // Version of deleted schema
    `long$result
  ]
 };
