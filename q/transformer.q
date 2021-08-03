/
* @file transformer.q
* @overview Define q functions to build a pipeline.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* This shared object name (`qtfm`) can vary according to if transformer
*  is used alone by q or statically linked to a messaging interface. If
*  the library is linked by Kafka interface for example, the library name
*  should be `kafkakdb`.
\ 
LIBPATH_: $[`qtfm.so in key `:src; `:src/qtfm; `qtfm] 2:;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Options of serialization and deserialization. These values must be passed
*  to `addSerializationLayer` and `addDeserializationLayer`.
\
.qtfm.METHOD:`NONE`QIPC`JSON`AVRO`PROTOBUF`MESSAGEPACK`ION`XML`PCAP`ZLIB`ZSTD`CUSTOM;
.qtfm.NONE:`.qtfm.METHOD$`NONE;
.qtfm.QIPC:`.qtfm.METHOD$`QIPC;
.qtfm.JSON:`.qtfm.METHOD$`JSON;
.qtfm.AVRO:`.qtfm.METHOD$`AVRO;
.qtfm.PROTOBUF:`.qtfm.METHOD$`PROTOBUF;
.qtfm.MESSAGEPACK:`.qtfm.METHOD$`MESSAGEPACK;
.qtfm.ION:`.qtfm.METHOD$`ION;
.qtfm.XML:`.qtfm.METHOD$`XML;
.qtfm.PCAP:`.qtfm.METHOD$`PCAP;
.qtfm.ZLIB:`.qtfm.METHOD$`ZLIB;
.qtfm.ZSTD:`.qtfm.METHOD$`ZSTD;
.qtfm.CUSTOM:`.qtfm.METHOD$`CUSTOM;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

//%% Pipeline %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Create a new pipeline object internally.
* @param pipeline_name {symbol}: Name of the new pipeline.
\
.qtfm.createNewPipeline: LIBPATH_ (`create_new_pipeline; 1);

/
* @brief Destroy a pipeline object.
* @param pipeline_name {symbol}: Name of the pipeline to destroy.
\
.qtfm.destroyPipeline: LIBPATH_ (`destroy_pipeline; 1);

/
* @brief Get a list of existing pipeline names.
* @return List of pipeline names.
\
.qtfm.getExistingPipelineNames: LIBPATH_ (`get_existing_pipeline_names; 1);

/
* @brief Get information of the specified pipeline.
* @param pipeline_name {symbol}: Name of a pipeline to get information.
* @return 
* - table: Table of pipeline layers with these columns:
*   - layer {long}: Index of layer.
*   - method {symbol}: Name of conversion.
\
.qtfm.getPipelineInfo: LIBPATH_ (`get_pipeline_info; 1);

/
* @brief Add a new layer for serialization.
* @param pipeline_name {symbol}: Name of a pipeline to which the new layer is added.
* @param method {enum}: Method to serialize. Available options are below:
* - .qtfm.QIPC
* - .qtfm.JSON
* - .qtfm.AVRO
* - .qtfm.PROTOBUF
* - .qtfm.MESSAGEPACK
* - .qtfm.ION
* - .qtfm.ZLIB
* - .qtfm.ZSTD
* - .qtfm.CUSTOM
* @param option {variable}: Optional argument contingent on deserialization method:
* - symbol:
*   - Path to a schema file (Avro)
*   - Schema name (Protobuf) 
* - string: Schema contents (Avro)
* - tuple of (foreign; bool): Ion symbol table object and a flag to use text format for encoding (Ion)
* - int: Level of compression (Zstandard)
* - null: Otherwise
\
.qtfm.addSerializationLayer: LIBPATH_ (`add_serialization_layer; 3);

/
* @brief Add a new layer for deserialization.
* @param pipeline_name {symbol}: Name of a pipeline to which the new layer is added.
* @param method {enum}: Method to deserialize. Available options are below:
* - .qtfm.QIPC
* - .qtfm.JSON
* - .qtfm.AVRO
* - .qtfm.PROTOBUF
* - .qtfm.MESSAGEPACK
* - .qtfm.ION
* - .qtfm.XML
* - .qtfm.PCAP
* - .qtfm.ZLIB
* - .qtfm.ZSTD
* - .qtfm.CUSTOM
* @param option {variable}: Optional argument contingent on deserialization method:
* - symbol:
*   - Path to a schema file (Avro)
*   - Schema name (Protobuf) 
* - string: Schema contents (Avro)
* - foreign: Ion symbol table object (Ion)
* - dictionary: Dictionary of Xpath (for XML)
* - int: The maximum number of layers to parse (for Pcap)
* - null: Otherwise
\
.qtfm.addDeserializationLayer: LIBPATH_ (`add_deserialization_layer; 3);

/
* @brief Remove a layer from a pipeline with an index in the pipeline.
* @param pipeline_name {symbol}: Name of a pipeline from which a layer is removed.
* @param index {long}: Index of the layer to remove. You can check the index by `getPipelineInfo`.
* @return
* - symbol: Method name of the removed layer.
\
.qtfm.removeLayer: LIBPATH_ (`remove_layer; 2);

/
* @brief Compile a pipeline and generate a converter internally.
* @param pipeline_name {symbol}: Name of a pipeline to compile.
\
.qtfm.compile: LIBPATH_ (`compile; 1);

/
* @brief Do transformation with a compiled function for a specified pipeline.
* @param pipeline_name {symbol}: Name of a pipeline with which message is converted.
* @param message {string | bytes}: Message to convert.
* @return
* - string | bytes: Converted message.
\
.qtfm.transform: LIBPATH_ (`transform; 2);

//%% Utility %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Register an import path of prot file.
* @param file_path_ {string}: Path to a directory where proto files exist.
\
.qtfm.addProtoImportPath: LIBPATH_ (`AddProtoImportPath; 1);

/
* @brief Load a proto file.
* @param file_name {string}: Name of a proto file without any path. The path must be regstered
*  with `.qtfm.addProtoImportPath`.
\
.qtfm.importProtoFile: LIBPATH_ (`ImportProtoFile; 1);

/
* @brief Load an Ion symbol table from a file.
* @param file_path {string}: A file path of the Ion symbol table.
\
.qtfm.loadSymbolTable: LIBPATH_ (`load_symbol_table; 1);

/
* @brief Add a new symbol to the symbol table.
* @param local_table {foreign}: Local symbol table.
* @param symbol {symbol}: New symbol to add.
* @return 
* - int: Assigned symbol ID.
\
.qtfm.addNewSymbol: LIBPATH_ (`add_new_symbol; 2);

/
* @brief Display current contents of an Ion symol table.
* @param table {foreign}: Ion symbol table.
\
.qtfm.displaySymbolTable: LIBPATH_ (`display_symbol_table; 1);

/
* @brief Import an Ion shared symbol table to Ion local symbol table.
* @param local_table {foreign}: Local Ion symbol table.
* @param shared_table {foreign}: Shared Ion symbol table.
\
.qtfm.importSharedSymbolTable: LIBPATH_ (`import_shared_symbol_table; 2);

/
* @brief Get the maximum symbol ID of a symbol table.
* @param table {foreign}: Symbol table.
* @return Maximum symbol ID of the symbol table.
\
.qtfm.getMaxSymbolID: LIBPATH_ (`get_maximum_symbol_id; 1);

/
* @brief Load PCAP file.
* @param file_path_ {string}: Path to a PCAP file (Extension is one of '.pcap', '.pcapng' and '.zstd').
* @return {compound}: List of bytes representing packets.
\
.qtfm.loadPcapFile: LIBPATH_ (`load_pcap_file; 1);

//%% Internal Use %%//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/

/
* @brief Check if protobuf version matches the one linked for this library.
\
.qtfm.initProtobuf: LIBPATH_ (`Init; 1);

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//              Initialize Library State                 //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.qtfm.initProtobuf[];
