# User Guide of Transformer

## Overview

Transformer library is designed to do serialization/deserialization off the main thread to yield the main thread for more suitable tasks for q; therefore its implementation does not interact with q main thread by `k()`.

Regardless of linking this library being linked to another messaging interface or being used directly by q, a framework of the transformer is composed of 4 steps:

1. Build a pipeline
2. Add a serialization/deserialization layers to the pipeline
3. Compile the pipeline
4. Call the compiled converter via `transform` function.

The step 4 is done by either of two ways:

- q: `.qtfm.transform[pipeline_name; message]`
- C/C++: `K transform(K pipeline_name, K message)`

The latter case needs to include `qtfm.h`.

## Function Reference

This library provides methods for interacting with a pipeline under `.qtfm` namespace .

```txt

// Operate on pipeline
.qtfm.createNewPipeline        Create a new pipeline object internally.
.qtfm.destroyPipeline          Destroy a pipeline object.
.qtfm.getExistngPipelineNames  Get a list of existing pipeline names.
.qtfm.addSerializationLayer    Add a new layer for serialization.
.qtfm.addDeserializationLayer  Add a new layer for deserialization.
.qtfm.removeLayer              Remove a layer from a pipeline with an index in the pipeline.
.qtfm.getPipelineInfo          Get information of the specified pipeline.
.qtfm.compile                  Compile a pipeline and generate a converter internally.
.qtfm.transform                Do transformation with a compiled function for a specified pipeline.

// Utility
.qtfm.loadPcapFile             Load Pcap file.
.qtfm.addProtoImportPath       Path to a directory where proto files exist.
.qtfm.importProtoFile          Load a proto file.
.qtfm.loadSymbolTable          Load a Ion symbol table from a file.
.qtfm.addNewSymbol             Add a new symbol to the Ion symbol table.
.qtfm.displaySymbolTable          Write down a current Ion symol table.
.qtfm.importSharedSymbolTable  Import an Ion shared symbol table to an Ion local symbol table.
.qtfm.getMaxSymbolID           Get the maximum symbol ID of an Ion symbol table.

```

### Operation on Pipeline

#### `.qtfm.createNewPipeline[pipeline_name]`

Create a new pipeline object internally.

##### Parameters

- `pipeline_name` {symbol}: Name of the new pipeline.

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: super
q).qtfm.createNewPipeline[`super]
'pipeline already exist: super
```

#### `.qtfm.destroyPipeline[pipeline_name]`

Destroy a pipeline object.

##### Parameters

- `pipeline_name` {symbol}: Name of the pipeline to destroy.

##### Examples

```q
q).qtfm.destroyPipeline[`super]
pipeline was deleted: super
q).qtfm.destroyPipeline[`shy_boy]
'no such pipeline: shy_boy
```

#### `.qtfm.getExistngPipelineNames[]`

Get a list of existing pipeline names.

##### Return

- list of symbol: List of pipeline names.

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: super
q).qtfm.createNewPipeline[`hyper]
pipeline was created: hyper
q).qtfm.getExistingPipelineNames[]
`hyper`super
```

#### `.qtfm.addSerializationLayer[pipeline_name; method; option]`

Add a new layer for serialization.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline to which the new layer is added.
- `method` {enum}: Method to serialize. Available options are below:
  - .qtfm.QIPC
  - .qtfm.JSON
  - .qtfm.AVRO
  - .qtfm.PROTOBUF
  - .qtfm.MESSAGEPACK
  - .qtfm.ION
  - .qtfm.ZLIB
  - .qtfm.ZSTD
- `option` {variable}: Optional argument contingent on deserialization method:
  - string: Path to a schema file (for Avro etc.)
  - tuple of (foreign; bool): Ion symbol table object and a flag to use text format for encoding (Ion)
  - int: Level of compression (Zstandard)
  - null: Otherwise

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: super
q).qtfm.addSerializationLayer[`super; .qtfm.AVRO; "../schema/person.avsc"]
q).qtfm.addSerializationLayer[`super; .qtfm.ZLIB; (::)]
q).qtfm.addSerializationLayer[`super; .qtfm.ZLIB; (::)]
'layer already exists: zlib_compression
```

#### `.qtfm.addDeserializationLayer[pipeline_name; method; option]`

Add a new layer for deserialization.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline to which the new layer is added.
- `method` {enum}: Method to deserialize. Available options are below:
  - .qtfm.QIPC
  - .qtfm.JSON
  - .qtfm.AVRO
  - .qtfm.PROTOBUF
  - .qtfm.MESSAGEPACK
  - .qtfm.XML
  - .qtfm.PCAP
  - .qtfm.ZLIB
  - .qtfm.ZSTD
- `option` {variable}: Optional argument contingent on deserialization method:
  - string: Path to a schema file (for Avro etc.)
  - foreign: Ion symbol table object (Ion)
  - dictionary: Dictionary of Xpath (for XML)
  - int: The maximum number of layers to parse (for Pcap)
  - null: Otherwise

##### Examples

```q
q).qtfm.createNewPipeline[`hyper]
pipeline was created: hyper
q).qtfm.addDeserializationLayer[`hydro; .qtfm.ZLIB; (::)]
'no such pipeline: hydro
q).qtfm.addDeserializationLayer[`hyper; .qtfm.ZLIB; (::)]
q).qtfm.addDeserializationLayer[`hyper; .qtfm.AVRO; "../schema/person.avsc"]
```

#### `.qtfm.getPipelineInfo[pipeline_name]`

Get information of the specified pipeline.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline to get information.

##### Returns

Table of pipeline layers with these columns:

- layer {long}: Index of layer.
- method {symbol}: Name of conversion.

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: super
q).qtfm.addSerializationLayer[`super; .qtfm.AVRO; "../schema/person.avsc"]
q).qtfm.addSerializationLayer[`super; .qtfm.ZLIB; (::)]
q).qtfm.getPipelineInfo `super
layer method          
----------------------
0     serialize_to_avro
1     zlib_compression
```

#### `.qtfm.removeLayer[pipeline_name; index]`

Remove a layer from a pipeline with an index in the pipeline.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline from which a layer is removed.
- `index` {long}: Index of the layer to remove. You can check the index by `getPipelineInfo`.

##### Return

- symbol: Method name of the removed layer.

##### Examples

```q
.qtfm.createNewPipeline[`hyper]
pipeline was created: hyper
q).qtfm.addDeserializationLayer[`hyper; .qtfm.AVRO; "../schema/person.avsc"]
layer method         
---------------------
0     deserialize_avro
q).qtfm.removeLayer[`hyper; 0]
`deserialize_avro
q).qtfm.removeLayer[`hyper; 0]
'index out of bound
q).qtfm.removeLayer[`hiya; 0]
no such pipeline: hiya
q).qtfm.getPipelineInfo `hyper
layer method
------------
q).qtfm.addDeserializationLayer[`hyper; .qtfm.ZLIB; (::)]
q).qtfm.addDeserializationLayer[`hyper; .qtfm.AVRO; "../schema/person.avsc"]
q).qtfm.getPipelineInfo `hyper
layer method            
------------------------
0     zlib_decompression
1     deserialize_avro   
```

#### `.qtfm.compile[pipeline_name]`

Compile a pipeline and generate a converter internally.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline to compile.

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: hyper
q).qtfm.compile[`super]
this pipeline has no layer: super
q).qtfm.addSerializationLayer[`super; .qtfm.AVRO; "../schema/person.avsc"]
q).qtfm.compile[`super]
compiled pipeline: super
q).qtfm.compile[`illusion]
'no such pipeline: illusion
```

#### `.qtfm.transform[pipeline_name; message]`

Do transformation with a compiled function for a specified pipeline.

##### Parameters

- `pipeline_name` {symbol}: Name of a pipeline with which message is converted.
- `message` {string | bytes}: Message to convert.

##### Return

- string | bytes: Converted message.

##### Examples

```q
q).qtfm.createNewPipeline[`super]
pipeline was created: super
q).qtfm.addSerializationLayer[`super; .qtfm.AVRO; "../schema/person.avsc"]
q).qtfm.compile[`super]
compiled pipeline: super
q)person:`ID`First`Last`Phone`Age!(2; "Michael"; "Ford"; "0000A"; 33i)
q)encoded: .qtfm.transform[`super; person]
q)encoded
0x4f626a0104146176726f2e636f646563086e756c6c166176726f2e736368656d618c037b227..
```

### Utility

#### `.qtfm.loadPcapFile[file_path]`

Load Pcap file.

##### Parameters

- `file_path_` {string}: Path to a PCAP file (Extension is one of '.pcap', '.pcapng' and '.zstd').

##### Return

- compound list: List of bytes representing packets.

```q
q)packets:.qtfm.loadPcapFile "../schema/example.pcap";
```

#### `.qtfm.addProtoImportPath[file_path_]`

Register an import path of prot file.

##### Parameters

- `file_path_` {string}: Path to a directory where proto files exist.

##### Examples

See the example of `.qtfm.importProtoFile`.

#### `.qtfm.importProtoFile[file_name]`

Load a proto file.

##### Parameters

- `file_name` {string}: Name of a proto file without any path. The path must be regstered with `.qtfm.addProtoImportPath`.

##### Examples

```q
q).qtfm.addProtoImportPath "../schema/";
q).qtfm.importProtoFile "examples.proto";
```
#### `.qtfm.loadSymbolTable[file_path]`

Load a symbol table from a file.

##### Parameters

- `file_path` {string}: A file path of the symbol table.

##### Examples

```q
local: .qtfm.loadSymbolTable["schema/local_table.ion"]
```

#### `.qtfm.addNewSymbol[table; symbol]`

Add a new symbol to the symbol table.

##### Parameters

- `table` {foreign}: Symbol table.
- `symbol` {symbol}: New symbol to add.

##### Return
 
- int: Assigned symbol ID.

##### Examples

```q
q)local: .qtfm.loadSymbolTable "tables/local_table.ion"
q).qtfm.getMaxSymbolID local
9i
q).qtfm.addNewSymbol[shared; `some]
10i
q).qtfm.getMaxSymbolID local
10i
```

#### `.qtfm.displaySymbolTable[table]`

Display current contents of an Ion symol table.

##### Parameters

- `table` {foreign}: Symbol table.

##### Examples

```q
q)local: .qtfm.loadSymbolTable "tables/local_table.ion"
q).qtfm.displaySymbolTable local
"$ion_symbol_table::{}"
q).qtfm.addNewSymbol[[local; `some]
10i
q).qtfm.displaySymbolTable local
"$ion_symbol_table::{symbols:[\"some\"]}"
```

#### `.qtfm.importSharedSymbolTable[local_table; shared_table]`

Import a shared symbol table to local symbol table.

**WARNING!!:** You must NOT try to import a shared symbol table to a non-empty local symbol table. The underlying Ion library asserts an error for that and exits with an error status code, meaning q process is shutdown without any hope of recovery.

```q
q)shared: .qtfm.loadSymbolTable "tables/shared_table.ion"
q)local: .qtfm.loadSymbolTable "tables/local_table.ion"
q).qtfm.addNewSymbol[[local; `some]
10i
q).qtfm.importSharedSymbolTable[local; shared]
q: /home/ion-c-1.4.0/ionc/ion_symbol_table.c:1152: _ion_symbol_table_local_incorporate_symbols: Assertion `!symtab->has_local_symbols' failed.
```

##### Parameters

- `local_table` {foreign}: Local symbol table.
- `shared_table` {foreign}: Shared symbol table.

##### Examples

```q
q)\c 25 200
q)shared: .qtfm.loadSymbolTable "tables/shared_table.ion"
q)local: .qtfm.loadSymbolTable "tables/local_table.ion"
q).qtfm.getMaxSymbolID local 
9i
q).qtfm.displaySymbolTable local
"$ion_symbol_table::{}"
q).qtfm.importSharedSymbolTable[local; shared]
q).qtfm.getMaxSymbolID local
14i
q).qtfm.displaySymbolTable local
"$ion_symbol_table::{imports:[{name:\"ionkdb.example.symbols\",version:1,max_id:5}]}"
```

#### `.qtfm.getMaxSymbolID[table]`

Get the maximum symbol ID of an Ion symbol table.

##### Parameters

- `table` {foreign}: Symbol table.

##### Return

Maximum symbol ID of the Ion symbol table.

##### Examples

See the example of `.qtfm.addNewSymbol`.
