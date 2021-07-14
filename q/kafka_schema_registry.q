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
//  or consumer subscribes to a tipic.

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Private Functions                  //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @private
// @kind function
// @category Schema Registry
// @brief Build a HTTP POST message.
// @param host {string}: Target host.
// @param port {string}: Target port.
// @param endpoint {string}: Target endpoint following the host. The endpoint must start siwth "/".
// @param message {string}: HTTP message to post.
.kafka.build_post:{[host;port;endpoint;message;schema_type]
  text: "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" --data '{\"schema\":\"", message, "\", \"schemaType\": \"", schema_type, "\"}' ";
  text,: "http://", host, ":", port, endpoint;
  text
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Public Interface                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// @kind function
// @category SchemaRegistry
// @brief Register a schema to Kafka registry.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param topic {symbol}: Topic to which the schema is used.
// @param message {path}: HTTP message to post.
// @return 
// - long: Schema ID.
// @note The specified topic must exist on Confluent platform; otherwise an error
//   ```
//     "{\"error_code\":50001,\"message\":\"Register schema operation failed while writing to the Kafka store\"}"
//   ```
//  will be returned.
.kafka.registerSchema:{[host;port;topic;path;schema_type]

  schema: ssr[raze read0 hsym `$path; "\""; "\\\""];

  text: "curl -X POST -H \"Content-Type: application/vnd.schemaregistry.v1+json\" ";
  text,: "--data '{\"schema\":\"", schema, "\", \"schemaType\": \"", schema_type, "\"}' ";

  // Schema is registered against topic
  text,: "http://", string[host], ":", string[port], "/subjects/", string[topic], "-value/versions";
  
  show text;
  result: .j.k first system text;
  $[`error_code in key result;
    'result `message;
    `long$result `id
  ]
 };

// @kind function
// @category SchemaRegistry
// @brief Retrieve a schema from Kafka registry with a topic and a schema version.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param topic {symbol}: Topic to which the schema is used.
// @param version {symbol}: Version of the schema. Version number or `latest`.
// @return 
// - string: schema.
.kafka.getSchemaByTopic:{[host;port;topic;version]
  text: "curl -H \"Accept: application/vnd.schemaregistry.v1+json\" ";
  text,: "http://", string[host], ":", string[port], "/subjects/", string[topic], "-value/versions/", string[version];
  show text;
  result: .j.k first system text;
  $[`error_code in key result;
    'result `message;
    result `schema
  ]
 };

// @kind function
// @category SchemaRegistry
// @brief Retrieve a schema from Kafka registry with a nique schema ID.
// @param host {symbol}: Schema-registry host.
// @param port {number}: Schema-registry port.
// @param schema_id {number}: Globally unique schema ID.
.kafka.getSchemaByID:{[host;port;schema_id]
  text: "curl -H \"Accept: application/vnd.schemaregistry.v1+json\" ";
  text,: "http://", string[host], ":", string[port], "/schemas/ids/", string[schema_id];
  show text;
  result: .j.k first system text;
  $[`error_code in key result;
    'result `message;
    result `schema
  ]
 };
