public enum SwiftOptions {
    /// Dump list of actions to perform
    /// Other options: InternalDebugOpt
    case driver_print_actions
    /// Dump the contents of the output file map
    /// Other options: InternalDebugOpt
    case driver_print_output_file_map
    /// Dump the contents of the derived output file map
    /// Other options: InternalDebugOpt
    case driver_print_derived_output_file_map
    /// Dump list of job inputs and outputs
    /// Other options: InternalDebugOpt
    case driver_print_bindings
    /// Dump list of jobs to execute
    /// Other options: InternalDebugOpt
    case driver_print_jobs
    /// Alias of: driver_print_jobs
    case _HASH_HASH_HASH
    /// Skip execution of subtasks when performing compilation
    /// Other options: InternalDebugOpt
    case driver_skip_execution
    /// Use the given executable to perform compilations. Arguments can be passed as a ';' separated list
    /// Other options: InternalDebugOpt
    case driver_use_frontend_path(arg: String)
    /// With -v, dump information about why files are being rebuilt
    /// Other options: InternalDebugOpt
    case driver_show_incremental
    /// Show every step in the lifecycle of driver jobs
    /// Other options: InternalDebugOpt
    case driver_show_job_lifecycle
    /// Pass input files as filelists whenever possible
    /// Other options: InternalDebugOpt
    case driver_use_filelists
    /// Pass input or output file names as filelists if there are more than <n>
    /// Meta var name: <n>
    /// Other options: InternalDebugOpt
    case driver_filelist_threshold(arg: String)
    /// Alias of: driver_filelist_threshold
    case driver_filelist_threshold_EQ(arg: String)
    /// Use the given seed value to randomize batch-mode partitions
    /// Other options: InternalDebugOpt
    case driver_batch_seed(arg: String)
    /// Use the given number of batch-mode partitions, rather than partitioning dynamically
    /// Other options: InternalDebugOpt
    case driver_batch_count(arg: String)
    /// Use the given number as the upper limit on dynamic batch-mode partition size
    /// Other options: InternalDebugOpt
    case driver_batch_size_limit(arg: String)
    /// Force the use of response files for testing
    /// Other options: InternalDebugOpt
    case driver_force_response_files
    /// Always rebuild dependents of files that have been modified
    /// Other options: InternalDebugOpt
    case driver_always_rebuild_dependents
    /// Enables incremental build optimization that only produces one dependencies file
    /// Flags: DoesNotAffectIncrementalBuild
    case enable_only_one_dependency_file
    /// Disables incremental build optimization that only produces one dependencies file
    /// Flags: DoesNotAffectIncrementalBuild
    case disable_only_one_dependency_file
    /// Debug DriverGraph by verifying it after every import
    /// Other options: InternalDebugOpt
    case driver_verify_fine_grained_dependency_graph_after_every_import
    /// Enable the dependency verifier for each frontend job
    /// Flags: FrontendOption, HelpHidden
    case verify_incremental_dependencies
    /// Enable the strict forwarding of compilation context to downstream implicit module dependencies
    /// Flags: FrontendOption, HelpHidden
    case strict_implicit_module_context
    /// Disable the strict forwarding of compilation context to downstream implicit module dependencies
    /// Flags: FrontendOption, HelpHidden
    case no_strict_implicit_module_context
    /// Enable internal self-checks while compiling
    /// Flags: CacheInvariant, DoesNotAffectIncrementalBuild, FrontendOption
    /// Other groups: Group<internal_debug_Group>
    case compiler_assertions
    /// Don't verify input files for Clang modules if the module has been successfully validated or loaded during this build session
    /// Flags: FrontendOption
    case validate_clang_modules_once
    /// Use the last modification time of <file> as the underlying Clang build session timestamp
    /// Flags: ArgumentIsPath, FrontendOption
    case clang_build_session_file(arg: String)
    /// Disable using new swift-driver
    case disallow_forwarding_driver
    /// Emit dot files every time driver imports an fine-grained swiftdeps file.
    /// Other options: InternalDebugOpt
    case driver_emit_fine_grained_dependency_dot_file_after_every_import
    /// Emit dot files for every source file.
    /// Flags: FrontendOption, HelpHidden
    case emit_fine_grained_dependency_sourcefile_dot_files
    /// Set the driver mode to either 'swift' or 'swiftc'
    /// Flags: HelpHidden
    case driver_mode(arg: String)
    /// Display available options
    /// Flags: AutolinkExtractOption, FrontendOption, ModuleWrapOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case help
    /// Alias of: help
    case h
    /// Display available options, including hidden options
    /// Flags: FrontendOption, HelpHidden
    case help_hidden
    /// Show commands to run and use verbose output
    /// Flags: DoesNotAffectIncrementalBuild, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case v
    /// Print version information and exit
    /// Flags: FrontendOption
    case version
    /// Emit textual output in a parseable format
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case parseable_output
    /// Windows SDK Root
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <root>
    case windows_sdk_root(arg: String)
    /// Windows SDK Version
    /// Flags: FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <version>
    case windows_sdk_version(arg: String)
    /// VisualC++ Tools Root
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <root>
    case visualc_tools_root(arg: String)
    /// VisualC++ ToolSet Version
    /// Flags: FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <version>
    case visualc_tools_version(arg: String)
    /// Native Platform sysroot
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <sysroot>
    case sysroot(arg: String)
    /// Write output to <file>
    /// Flags: ArgumentIsPath, AutolinkExtractOption, CacheInvariant, FrontendOption, ModuleWrapOption, NoInteractiveOption, SwiftAPIDigesterOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <file>
    case o(arg: String)
    /// Number of commands to execute in parallel
    /// Flags: DoesNotAffectIncrementalBuild
    /// Meta var name: <n>
    case j(arg: String)
    /// Compile against <sdk>
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <sdk>
    case sdk(arg: String)
    /// Interpret input according to a specific Swift language version number
    /// Flags: FrontendOption, ModuleInterfaceOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <vers>
    case swift_version(arg: String)
    /// Interpret input according to a specific Swift language mode
    /// Flags: FrontendOption, ModuleInterfaceOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <mode>
    /// Alias of: swift_version
    case language_mode(arg: String)
    /// The version number to be applied on the input for the PackageDescription availability kind
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    /// Meta var name: <vers>
    case package_description_version(arg: String)
    /// The version of the Swift compiler used to generate a .swiftinterface file
    /// Flags: FrontendOption, HelpHidden
    /// Meta var name: <intcvers>
    case swiftinterface_compiler_version(arg: String)
    /// Look for external executables (ld, clang, binutils) in <directory>
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <directory>
    case tools_directory(arg: String)
    /// Marks a conditional compilation flag as true
    /// Flags: FrontendOption
    case D(arg: String)
    /// Executes a line of code provided on the command line
    /// Flags: NewDriverOnlyOption
    case e(arg: String)
    /// Add directory to framework search path
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case F(arg: String)
    /// Flags: ArgumentIsPath, FrontendOption
    /// Alias of: F
    case F_EQ(arg: String)
    /// Add directory to system framework search path
    /// Flags: ArgumentIsPath, FrontendOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case Fsystem(arg: String)
    /// Add directory to the import search path
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case I(arg: String)
    /// Flags: ArgumentIsPath, FrontendOption
    /// Alias of: I
    case I_EQ(arg: String)
    /// Add directory to the system import search path
    /// Flags: ArgumentIsPath, FrontendOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case Isystem(arg: String)
    /// Implicitly imports the Objective-C half of a module
    /// Flags: FrontendOption, NoInteractiveOption
    case import_underlying_module
    /// Implicitly imports an Objective-C header file
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden
    case import_objc_header(arg: String)
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden
    /// Alias of: import_objc_header
    case import_bridging_header(arg: String)
    /// Import bridging header PCH file
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden
    case import_pch(arg: String)
    /// Directory to persist automatically created precompiled bridging headers
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden
    case pch_output_dir(arg: String)
    /// Automatically chaining all the bridging headers
    /// Flags: FrontendOption, HelpHidden
    case auto_bridging_header_chaining
    /// Do not automatically chaining all the bridging headers
    /// Flags: FrontendOption, HelpHidden
    case no_auto_bridging_header_chaining
    /// Perform an incremental build if possible
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden, NoInteractiveOption
    case incremental
    /// Don't search the standard library or toolchain import paths for modules
    /// Flags: FrontendOption
    case nostdimport
    /// Don't search the standard library import path for modules
    /// Flags: FrontendOption
    case nostdlibimport
    /// A file which specifies the location of outputs
    /// Flags: ArgumentIsPath, NoInteractiveOption
    /// Meta var name: <path>
    case output_file_map(arg: String)
    /// Flags: ArgumentIsPath, NoInteractiveOption
    /// Alias of: output_file_map
    case output_file_map_EQ(arg: String)
    /// Save intermediate compilation results
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case save_temps
    /// Prints the total time it took to execute all compilation tasks
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case driver_time_compilation
    /// Directory to write unified compilation-statistics files to
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden
    case stats_output_dir(arg: String)
    /// Prints all stats even if they are zero
    /// Flags: FrontendOption, HelpHidden
    case print_zero_stats
    /// Enable per-request timers
    /// Flags: FrontendOption, HelpHidden
    case fine_grained_timers
    /// Trace changes to stats in -stats-output-dir
    /// Flags: FrontendOption, HelpHidden
    case trace_stats_events
    /// Skip type-checking and SIL generation for non-inlinable function bodies
    /// Flags: FrontendOption, HelpHidden
    case experimental_skip_non_inlinable_function_bodies
    /// Skip work on non-inlinable function bodies that do not declare nested types
    /// Flags: FrontendOption, HelpHidden
    case experimental_skip_non_inlinable_function_bodies_without_types
    /// Profile changes to stats in -stats-output-dir
    /// Flags: FrontendOption, HelpHidden
    case profile_stats_events
    /// Profile changes to stats in -stats-output-dir, subdivided by source entity
    /// Flags: FrontendOption, HelpHidden
    case profile_stats_entities
    /// Emit basic Make-compatible dependencies files
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_dependencies
    /// Track system dependencies while emitting Make-style dependencies
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    case track_system_dependencies
    /// Emit a JSON file containing information about what modules were loaded
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_loaded_module_trace
    /// Emit the loaded module trace JSON to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_loaded_module_trace_path(arg: String)
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_loaded_module_trace_path
    case emit_loaded_module_trace_path_EQ(arg: String)
    /// Emit a remark if a cross-import of a module is triggered.
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case emit_cross_import_remarks
    /// Emit remarks about loaded module
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_loading_module
    /// Emit remarks about contextual inconsistencies in loaded modules
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_module_recovery
    /// Emit remarks about the import bridging in each element composing the API
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_module_api_import
    /// Emit remarks about loaded macro implementations
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_macro_loading
    /// Emit a remark when indexing a system module
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_indexing_system_module
    /// Emit a remark if an explicit module interface invocation has an early exit because the expected output is up-to-date
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_skip_explicit_interface_build
    /// Emit remarks about module serialization
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case remark_module_serialization
    /// Emit a TBD file
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_tbd
    /// Emit the TBD file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_tbd_path(arg: String)
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_tbd_path
    case emit_tbd_path_EQ(arg: String)
    /// Embed symbols from the module in the emitted tbd file
    /// Flags: FrontendOption
    case embed_tbd_for_module(arg: String)
    /// Serialize diagnostics in a binary format
    /// Flags: CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    case serialize_diagnostics
    /// Emit a serialized diagnostics file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoBatchOption, SupplementaryOutput, SwiftAPIDigesterOption
    /// Meta var name: <path>
    case serialize_diagnostics_path(arg: String)
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoBatchOption, SupplementaryOutput, SwiftAPIDigesterOption
    /// Alias of: serialize_diagnostics_path
    case serialize_diagnostics_path_EQ(arg: String)
    /// Print diagnostics in color
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case color_diagnostics
    /// Do not print diagnostics in color
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case no_color_diagnostics
    /// Include diagnostic names when printing
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case debug_diagnostic_names
    /// Include diagnostic groups in printed diagnostic output, if available
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case print_diagnostic_groups
    /// Include educational notes in printed diagnostic output, if available
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case print_educational_notes
    /// The formatting style used when printing diagnostics ('swift' or 'llvm')
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <style>
    case diagnostic_style(arg: String)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <style>
    /// Alias of: diagnostic_style
    case diagnostic_style_EQ(arg: String)
    /// Choose a language for diagnostic messages
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <locale-code>
    case locale(arg: String)
    /// Path to localized diagnostic messages directory
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <path>
    case localization_path(arg: String)
    /// Specifies the module cache path
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case module_cache_path(arg: String)
    /// Build the module to allow binary-compatible library evolution
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_library_evolution
    /// Warn on public declarations without an availability attribute
    /// Flags: FrontendOption, NoInteractiveOption
    case require_explicit_availability
    /// Set diagnostic level to report public declarations without an availability attribute
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <error,warn,ignore>
    case require_explicit_availability_EQ(arg: String)
    /// Suggest fix-its adding @available(<target>, *) to public declarations without availability
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <target>
    case require_explicit_availability_target(arg: String)
    /// Require explicit Sendable annotations on public declarations
    /// Flags: FrontendOption, NoInteractiveOption
    case require_explicit_sendable
    /// Define an availability macro in the format 'macroName : iOS 13.0, macOS 10.15'
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <macro>
    case define_availability(arg: String)
    /// Deprecated, has no effect
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case check_api_availability_only
    /// Specify the optimization mode for unavailable declarations. The value may be 'none' (no optimization) or 'complete' (code is not generated at all unavailable declarations)
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <complete,none>
    case unavailable_decl_optimization_EQ(arg: String)
    /// Defines a custom availability domain that is available at compile time
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoInteractiveOption
    /// Meta var name: <domain>
    case define_enabled_availability_domain(arg: String)
    /// Defines a custom availability domain that is unavailable at compile time
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoInteractiveOption
    /// Meta var name: <domain>
    case define_disabled_availability_domain(arg: String)
    /// Defines a custom availability domain that can be enabled or disabled at runtime
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoInteractiveOption
    /// Meta var name: <domain>
    case define_dynamic_availability_domain(arg: String)
    /// Deprecated; has no effect
    /// Flags: FrontendOption
    case experimental_package_bypass_resilience
    /// Deprecated; use -allow-non-resilient-access instead
    /// Flags: FrontendOption
    case experimental_allow_non_resilient_access
    /// Ensures all contents are generated besides exportable decls in the binary module, so non-resilient access can be allowed
    /// Flags: FrontendOption
    case allow_non_resilient_access
    /// Library distribution level 'api', 'spi' or 'other' (the default)
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    /// Meta var name: <level>
    case library_level(arg: String)
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    /// Meta var name: <level>
    /// Alias of: library_level
    case library_level_EQ(arg: String)
    /// Name of the module to build
    /// Flags: FrontendOption, ModuleInterfaceOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case module_name(arg: String)
    /// Name of the project this module to build belongs to
    /// Flags: FrontendOption, ModuleInterfaceOptionIgnorable, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case project_name(arg: String)
    /// Flags: FrontendOption
    /// Alias of: module_name
    case module_name_EQ(arg: String)
    /// If a source file imports or references module <alias_name>, the <real_name> is used for the contents of the file
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Meta var name: <alias_name=real_name>
    case module_alias(arg: String)
    /// Library to link against when using this module
    /// Flags: FrontendOption, ModuleInterfaceOption
    case module_link_name(arg: String)
    /// Flags: FrontendOption
    /// Alias of: module_link_name
    case module_link_name_EQ(arg: String)
    /// Force ld to link against this module even if no symbols are used
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    case autolink_force_load
    /// ABI name to use for the contents of this module
    /// Flags: FrontendOption, ModuleInterfaceOption
    case module_abi_name(arg: String)
    /// Name of the package the module belongs to
    /// Flags: FrontendOption, ModuleInterfaceOption
    case package_name(arg: String)
    /// Module name to use when referenced in clients module interfaces
    /// Flags: FrontendOption, ModuleInterfaceOption
    case export_as(arg: String)
    /// Public facing module name to use in diagnostics and documentation
    /// Flags: FrontendOption, ModuleInterfaceOptionIgnorable
    case public_module_name(arg: String)
    /// Emit an importable module
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_module
    /// Emit an importable module to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_path(arg: String)
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_module_path
    case emit_module_path_EQ(arg: String)
    /// Emit an importable module for the target variant at the specified path
    /// Flags: ArgumentIsPath, CacheInvariant, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_module_path(arg: String)
    /// Output module summary file
    /// Flags: NoInteractiveOption, SupplementaryOutput
    case emit_module_summary
    /// Output module summary file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_summary_path(arg: String)
    /// Output module interface file
    /// Flags: NoInteractiveOption, SupplementaryOutput
    case emit_module_interface
    /// Output module interface file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_interface_path(arg: String)
    /// Output module interface file for the target variant to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_module_interface_path(arg: String)
    /// Output private module interface file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_private_module_interface_path(arg: String)
    /// Output private module interface file for the target variant to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_private_module_interface_path(arg: String)
    /// Output package module interface file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_package_module_interface_path(arg: String)
    /// Output package module interface file for the target variant to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_package_module_interface_path(arg: String)
    /// Check that module interfaces emitted during compilation typecheck
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case verify_emitted_module_interface
    /// Don't check that module interfaces emitted during compilation typecheck
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, ModuleInterfaceOptionIgnorable, NoInteractiveOption
    case no_verify_emitted_module_interface
    /// don't emit Swift source info file
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case avoid_emit_module_source_info
    /// Output module source info file to <path>
    /// Flags: ArgumentIsPath, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_source_info_path(arg: String)
    /// Output module source info file for the target variant to <path>
    /// Flags: ArgumentIsPath, FrontendOption, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_module_source_info_path(arg: String)
    /// Flags: HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_module_interface
    case emit_parseable_module_interface
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_module_interface_path
    case emit_parseable_module_interface_path(arg: String)
    /// Flags: NoInteractiveOption, SupplementaryOutput
    case emit_const_values
    /// Emit the extracted compile-time known values to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_const_values_path(arg: String)
    /// Output a JSON file describing the module's API
    /// Flags: CacheInvariant, NoInteractiveOption, SupplementaryOutput
    case emit_api_descriptor
    /// Output a JSON file describing the module's API to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_api_descriptor_path(arg: String)
    /// Output a JSON file describing the target variant module's API to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_variant_api_descriptor_path(arg: String)
    /// Emit an Objective-C header file
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_objc_header
    /// Emit an Objective-C header file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_objc_header_path(arg: String)
    /// Augment emitted Objective-C header with textual imports for every included modular import
    /// Flags: FrontendOption, NoInteractiveOption, SupplementaryOutput
    case emit_clang_header_nonmodular_includes
    /// Emit an Objective-C and C++ header file to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, NoInteractiveOption, SupplementaryOutput
    /// Alias of: emit_objc_header_path
    case emit_clang_header_path(arg: String)
    /// Make this module statically linkable and make the output of -emit-library a static library.
    /// Flags: FrontendOption, ModuleInterfaceOption, NoInteractiveOption
    case `static`
    /// Recognize and import CF types as class types
    /// Flags: FrontendOption, HelpHidden
    case import_cf_types
    /// Set the upper bound for memory consumption, in bytes, by the constraint solver
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case solver_memory_threshold(arg: String)
    /// Set The upper bound to number of sub-expressions unsolved before termination of the shrink phrase
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case solver_shrink_unsolved_threshold(arg: String)
    /// Set the maximum depth for direct recursion in value types
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case value_recursion_threshold(arg: String)
    /// Disable using the swift bridge attribute
    /// Flags: FrontendOption, HelpHidden
    case disable_swift_bridge_attr
    /// Enable automatic generation of bridging PCH files
    /// Flags: HelpHidden
    case enable_bridging_pch
    /// Disable automatic generation of bridging PCH files
    /// Flags: HelpHidden
    case disable_bridging_pch
    /// Specify the LTO type to either 'llvm-thin' or 'llvm-full'
    /// Flags: FrontendOption, NoInteractiveOption
    case lto(arg: String)
    /// Perform LTO with <lto-library>
    /// Flags: ArgumentIsPath, FrontendOption, NoInteractiveOption
    /// Meta var name: <lto-library>
    case lto_library(arg: String)
    /// Specify YAML file to override attributes on Swift declarations in this module
    /// Flags: ArgumentIsPath, FrontendOption
    case access_notes_path(arg: String)
    /// Flags: ArgumentIsPath, FrontendOption
    /// Alias of: access_notes_path
    case access_notes_path_EQ(arg: String)
    /// Enable experimental forward mode differentiation
    /// Flags: FrontendOption
    case enable_experimental_forward_mode_differentiation
    /// Enable experimental 'AdditiveArithmetic' derived conformances
    /// Flags: FrontendOption
    case enable_experimental_additive_arithmetic_derivation
    /// Enable experimental concise '#file' identifier
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_experimental_concise_pound_file
    /// Enable experimental C++ interop code generation and config directives
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_cxx_interop
    /// Enables C++ interoperability; pass 'default' to enable or 'off' to disable
    /// Flags: FrontendOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case cxx_interoperability_mode(arg: String)
    /// Enable experimental C foreign references types (with reference counting).
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    case experimental_c_foreign_reference_types
    /// Library code can assume that all clients are visible at linktime, and aggressively strip unused code
    /// Flags: FrontendOption, HelpHidden
    case experimental_hermetic_seal_at_link
    /// Enables loading a package interface if in the same package specified with package-name
    /// Flags: FrontendOption, HelpHidden
    case experimental_package_interface_load
    /// Enables seriailzation/deserialization of debug scopes
    /// Flags: FrontendOption, HelpHidden
    case experimental_serialize_debug_info
    /// Suppress all warnings
    /// Flags: FrontendOption
    case suppress_warnings
    /// Treat warnings as errors
    /// Flags: FrontendOption
    /// Other groups: Group<warning_treating_Group>
    case warnings_as_errors
    /// Treat this warning group as error
    /// Flags: FrontendOption, HelpHidden
    /// Meta var name: <diagnostic_group>
    /// Other groups: Group<warning_treating_Group>
    case Werror(arg: String)
    /// Treat warnings as warnings
    /// Flags: FrontendOption
    /// Other groups: Group<warning_treating_Group>
    case no_warnings_as_errors
    /// Treat this warning group as warning
    /// Flags: FrontendOption, HelpHidden
    /// Meta var name: <diagnostic_group>
    /// Other groups: Group<warning_treating_Group>
    case Wwarning(arg: String)
    /// Suppress all remarks
    /// Flags: FrontendOption
    case suppress_remarks
    /// Continue building, even after errors are encountered
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case continue_building_after_errors
    /// Deprecated, has no effect
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case warn_swift3_objc_inference_complete
    /// Deprecated, has no effect
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case warn_swift3_objc_inference_minimal
    /// Emit runtime checks for actor data races
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case enable_actor_data_race_checks
    /// Disable runtime checks for actor data races
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case disable_actor_data_race_checks
    /// Disable dynamic actor isolation checks
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case disable_dynamic_actor_isolation
    /// Enable the use of forward slash regular-expression literal syntax
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_bare_slash_regex
    /// Warn about implicit overrides of protocol members
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case warn_implicit_overrides
    /// Warn when soft-deprecated declarations are referenced
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    case warn_soft_deprecated
    /// Limit the number of times the compiler will attempt typo correction to <n>
    /// Flags: FrontendOption, HelpHidden
    /// Meta var name: <n>
    case typo_correction_limit(arg: String)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden
    /// Alias of: warn_swift3_objc_inference_complete
    case warn_swift3_objc_inference
    /// Warn about code that is unsafe according to the Swift Concurrency model and will become ill-formed in a future language version
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case warn_concurrency
    /// Specify the how strict concurrency checking will be. The value may be 'minimal' (most 'Sendable' checking is disabled), 'targeted' ('Sendable' checking is enabled in code that uses the concurrency model, or 'complete' ('Sendable' and other checking is enabled for all code in the module)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case strict_concurrency(arg: String)
    /// Enable an experimental feature
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_experimental_feature(arg: String)
    /// Disable an experimental feature
    /// Flags: FrontendOption, ModuleInterfaceOption
    case disable_experimental_feature(arg: String)
    /// Enable a feature that will be introduced in an upcoming language version
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_upcoming_feature(arg: String)
    /// Disable a feature that will be introduced in an upcoming language version
    /// Flags: FrontendOption, ModuleInterfaceOption
    case disable_upcoming_feature(arg: String)
    /// Report performed transformations by optimization passes whose name matches the given POSIX regular expression
    /// Flags: FrontendOption
    case Rpass_EQ(arg: String)
    /// Report missed transformations by optimization passes whose name matches the given POSIX regular expression
    /// Flags: FrontendOption
    case Rpass_missed_EQ(arg: String)
    /// Generate a YAML optimization record file
    /// Flags: FrontendOption
    case save_optimization_record
    /// Generate an optimization record file in a specific format (default: YAML)
    /// Flags: FrontendOption
    /// Meta var name: <format>
    case save_optimization_record_EQ(arg: String)
    /// Specify the file name of any generated optimization record
    /// Flags: ArgumentIsPath, FrontendOption
    case save_optimization_record_path(arg: String)
    /// Only include passes which match a specified regular expression in the generated optimization record (by default, include all passes)
    /// Flags: FrontendOption
    /// Meta var name: <regex>
    case save_optimization_record_passes(arg: String)
    /// Diagnose any code that needs to heap allocate (classes, closures, etc.)
    /// Flags: FrontendOption, HelpHidden
    case no_allocations
    /// Restrict code to those available for App Extensions
    /// Flags: FrontendOption, NoInteractiveOption
    case enable_app_extension
    /// Restrict code to those available for App Extension Libraries
    /// Flags: FrontendOption, NoInteractiveOption
    case enable_app_extension_library
    /// libc runtime library to use
    /// Flags: SwiftSymbolGraphExtractOption
    case libc(arg: String)
    /// Specifies a library which should be linked against
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    /// Other groups: Group<linker_option_Group>
    case l(arg: String)
    /// Specifies a framework which should be linked against
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    /// Other groups: Group<linker_option_Group>
    case framework(arg: String)
    /// Add directory to library link search path
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, SwiftSymbolGraphExtractOption
    /// Other groups: Group<linker_option_Group>
    case L(arg: String)
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    /// Alias of: L
    /// Other groups: Group<linker_option_Group>
    case L_EQ(arg: String)
    /// Deprecated
    /// Flags: DoesNotAffectIncrementalBuild
    case link_objc_runtime
    /// Deprecated
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden
    case no_link_objc_runtime
    /// Statically link the Swift standard library
    /// Flags: DoesNotAffectIncrementalBuild
    case static_stdlib
    /// Don't statically link the Swift standard library
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden
    case no_static_stdlib
    /// Add an rpath entry for the toolchain's standard library, rather than the OS's
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden
    case toolchain_stdlib_rpath
    /// Do not add an rpath entry for the toolchain's standard library (default)
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden
    case no_toolchain_stdlib_rpath
    /// Don't add any rpath entries.
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden
    case no_stdlib_rpath
    /// Statically link the executable
    case static_executable
    /// Don't statically link the executable
    /// Flags: HelpHidden
    case no_static_executable
    /// Specifies the flavor of the linker to be used
    /// Flags: DoesNotAffectIncrementalBuild
    case use_ld(arg: String)
    /// Specifies the path to the linker to be used
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, HelpHidden
    case ld_path(arg: String)
    /// Specifies an option which should be passed to the linker
    /// Flags: DoesNotAffectIncrementalBuild
    case Xlinker(arg: String)
    /// Specify the build ID argument passed to the linker
    /// Flags: NewDriverOnlyOption
    /// Meta var name: <build-id>
    case build_id(arg: String)
    /// Flags: NewDriverOnlyOption
    /// Alias of: build_id
    case build_id_EQ(arg: String)
    /// Compile without any optimization
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Other groups: Group<O_Group>
    case Onone
    /// Compile with optimizations
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Other groups: Group<O_Group>
    case O
    /// Compile with optimizations and target small code size
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Other groups: Group<O_Group>
    case Osize
    /// Compile with optimizations and remove runtime safety checks
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Other groups: Group<O_Group>
    case Ounchecked
    /// Compile with optimizations appropriate for a playground
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    /// Other groups: Group<O_Group>
    case Oplayground
    /// Abort if a deserialization error is found while package optimization is enabled
    /// Flags: FrontendOption
    case ExperimentalPackageCMOAbortOnDeserializationFail
    /// Deprecated; use -package-cmo instead
    /// Flags: FrontendOption
    case ExperimentalPackageCMO
    /// Enable optimization to perform defalut CMO within a package boundary
    /// Flags: FrontendOption
    case PackageCMO
    /// Perform conservative cross-module optimization
    /// Flags: FrontendOption, HelpHidden
    case EnableDefaultCMO
    /// Perform cross-module optimization on everything (all APIs). This is the same level of serialization as Embedded Swift.
    /// Flags: FrontendOption, HelpHidden
    case EnableCMOEverything
    /// Perform cross-module optimization
    /// Flags: FrontendOption, HelpHidden
    case CrossModuleOptimization
    /// Disable cross-module optimization
    /// Flags: FrontendOption, HelpHidden
    case disableCrossModuleOptimization
    /// Deprecated, has no effect
    /// Flags: FrontendOption, HelpHidden
    case ExperimentalPerformanceAnnotations
    /// Remove runtime safety checks.
    /// Flags: FrontendOption
    case RemoveRuntimeAsserts
    /// Assume that code will be executed in a single-threaded environment
    /// Flags: FrontendOption, HelpHidden
    case AssumeSingleThreaded
    /// Emit debug info. This is the preferred setting for debugging with LLDB.
    /// Flags: FrontendOption
    /// Other groups: Group<g_Group>
    case g
    /// Don't emit debug info
    /// Flags: FrontendOption
    /// Other groups: Group<g_Group>
    case gnone
    /// Emit minimal debug info for backtraces only
    /// Flags: FrontendOption
    /// Other groups: Group<g_Group>
    case gline_tables_only
    /// Emit full DWARF type info.
    /// Flags: FrontendOption
    /// Other groups: Group<g_Group>
    case gdwarf_types
    /// Remap source paths in debug info
    /// Flags: FrontendOption
    /// Meta var name: <prefix=replacement>
    case debug_prefix_map(arg: String)
    /// Remap source paths in coverage info
    /// Flags: FrontendOption
    /// Meta var name: <prefix=replacement>
    case coverage_prefix_map(arg: String)
    /// Remap source paths in debug, coverage, and index info
    /// Flags: FrontendOption
    /// Meta var name: <prefix=replacement>
    case file_prefix_map(arg: String)
    /// The compilation directory to embed in the debug info. Coverage mapping is not supported yet.
    /// Flags: FrontendOption
    /// Meta var name: <path>
    case file_compilation_dir(arg: String)
    /// Specify the debug info format type to either 'dwarf' or 'codeview'
    /// Flags: FrontendOption
    case debug_info_format(arg: String)
    /// DWARF debug info version to produce if requested
    /// Flags: FrontendOption
    /// Meta var name: <version>
    case dwarf_version(arg: String)
    /// Apply debug prefix mappings to serialized debug info in Swiftmodule files
    /// Flags: FrontendOption
    case prefix_serialized_debugging_options
    /// Verify the binary representation of debug output.
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    case verify_debug_info
    /// Emit the compiler invocation in the debug info.
    /// Flags: FrontendOption
    case debug_info_store_invocation
    /// Specify the assert_configuration replacement. Possible values are Debug, Release, Unchecked, DisableReplacement.
    /// Flags: FrontendOption, ModuleInterfaceOption
    case AssertConfig(arg: String)
    /// Use tabs for indentation.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Other groups: Group<code_formatting_Group>
    case use_tabs
    /// Indent cases in switch statements.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Other groups: Group<code_formatting_Group>
    case indent_switch_case
    /// Overwrite input file with formatted file.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Other groups: Group<code_formatting_Group>
    case in_place
    /// Width of tab character.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Meta var name: <n>
    /// Other groups: Group<code_formatting_Group>
    case tab_width(arg: String)
    /// Number of characters to indent.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Meta var name: <n>
    /// Other groups: Group<code_formatting_Group>
    case indent_width(arg: String)
    /// <start line>:<end line>. Formats a range of lines (1-based). Can only be used with one input file.
    /// Flags: NoBatchOption, NoInteractiveOption
    /// Meta var name: <n:n>
    /// Other groups: Group<code_formatting_Group>
    case line_range(arg: String)
    /// Update Swift code
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoInteractiveOption
    case update_code
    /// When migrating, add '@objc' to declarations that would've been implicitly visible in Swift 3
    /// Flags: FrontendOption, NoInteractiveOption
    case migrate_keep_objc_visibility
    /// Disable the Migrator phase which automatically applies fix-its
    /// Flags: FrontendOption, NoInteractiveOption
    case disable_migrator_fixits
    /// Emit the replacement map describing Swift Migrator changes to <path>
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoDriverOption, NoInteractiveOption
    /// Meta var name: <path>
    case emit_remap_file_path(arg: String)
    /// Emit the migrated source file to <path>
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoDriverOption, NoInteractiveOption
    /// Meta var name: <path>
    case emit_migrated_file_path(arg: String)
    /// Dump the input text, output text, and states for migration to <path>
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <path>
    case dump_migration_states_dir(arg: String)
    /// API migration data is from <path>
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <path>
    case api_diff_data_file(arg: String)
    /// Load platform and version specific API migration data files from <path>. Ignored if -api-diff-data-file is specified.
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <path>
    case api_diff_data_dir(arg: String)
    /// Dump USR for each declaration reference
    /// Flags: FrontendOption, NoInteractiveOption
    case dump_usr
    /// Does nothing. Temporary compatibility flag for Xcode.
    /// Flags: FrontendOption, NoInteractiveOption
    case migrator_update_sdk
    /// Does nothing. Temporary compatibility flag for Xcode.
    /// Flags: FrontendOption, NoInteractiveOption
    case migrator_update_swift
    /// Parse the input file(s) as libraries, not scripts
    /// Flags: FrontendOption, NoInteractiveOption
    case parse_as_library
    /// Parse the input file as SIL code, not Swift source
    /// Flags: FrontendOption, NoInteractiveOption
    case parse_sil
    /// Parse the input file(s) as the Swift standard library
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption
    case parse_stdlib
    /// Enables the explicit import of the Builtin module
    /// Flags: FrontendOption, ModuleInterfaceOption
    case enable_builtin_module
    /// Emit object file(s) (-c)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_object
    /// Emit assembly file(s) (-S)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_assembly
    /// Emit LLVM BC file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_bc
    /// Emit LLVM IR file(s) before LLVM optimizations
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_irgen
    /// Emit LLVM IR file(s) after LLVM optimizations
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_ir
    /// Emit canonical SIL file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_sil
    /// Emit raw SIL file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_silgen
    /// Emit lowered SIL file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_lowered_sil
    /// Emit serialized AST + canonical SIL file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_sib
    /// Emit serialized AST + raw SIL file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_sibgen
    /// Emit a list of the imported modules
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_imported_modules
    /// Emit a precompiled Clang module from a module map
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_pcm
    /// Emit a linked executable
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_executable
    /// Emit a linked library
    /// Flags: NoInteractiveOption
    /// Other options: ModeOpt
    case emit_library
    /// Flags: FrontendOption, NoInteractiveOption
    /// Alias of: emit_object
    /// Other options: ModeOpt
    case c
    /// Flags: FrontendOption, NoInteractiveOption
    /// Alias of: emit_assembly
    /// Other options: ModeOpt
    case S
    /// Apply all fixits from diagnostics without any filtering
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    case fixit_all
    /// Parse input file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case parse
    /// Parse and resolve imports in input file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case resolve_imports
    /// Parse and type-check input file(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case typecheck
    /// Parse input file(s) and dump AST(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case dump_parse
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Alias of: dump_parse
    case emit_parse
    /// Parse and type-check input file(s) and dump AST(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case dump_ast
    /// Desired format for -dump-ast output ('default', 'json', or 'json-zlib'); no format is guaranteed stable across different compiler versions
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <format>
    case dump_ast_format(arg: String)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Alias of: dump_ast
    case emit_ast
    /// Parse and type-check input file(s) and dump the scope map(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Meta var name: <expanded-or-list-of-line:column>
    /// Other options: ModeOpt
    case dump_scope_maps(arg: String)
    /// Type-check input file(s) and dump availability scopes
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case dump_availability_scopes
    /// Output YAML dump of fixed-size types from all imported modules
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case dump_type_info
    /// Parse and type-check input file(s) and pretty print AST(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case print_ast
    /// Parse and type-check input file(s) and pretty print declarations from AST(s)
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case print_ast_decl
    /// Dump debugging information about a precompiled Clang module
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case dump_pcm
    /// REPL mode (the default if there is no input file)
    /// Flags: FrontendOption, HelpHidden, NoBatchOption
    /// Other options: ModeOpt
    case repl
    /// LLDB-enhanced REPL mode
    /// Flags: HelpHidden, NoBatchOption
    /// Other options: ModeOpt
    case lldb_repl
    /// Flags: FrontendOption, NoBatchOption
    /// Other options: ModeOpt
    case deprecated_integrated_repl
    /// Other options: ModeOpt
    case i
    /// Optimize input files together instead of individually
    /// Flags: FrontendOption, NoInteractiveOption
    case whole_module_optimization
    /// Disable optimizing input files together instead of individually
    /// Flags: FrontendOption, NoInteractiveOption
    case no_whole_module_optimization
    /// Enable combining frontend jobs into batches
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case enable_batch_mode
    /// Disable combining frontend jobs into batches
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case disable_batch_mode
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    /// Alias of: whole_module_optimization
    case wmo
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    /// Alias of: whole_module_optimization
    case force_single_frontend_invocation
    /// Enable multi-threading and specify number of threads
    /// Flags: CacheInvariant, DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <n>
    case num_threads(arg: String)
    /// Pass <arg> to the Swift frontend
    /// Flags: HelpHidden
    /// Meta var name: <arg>
    case Xfrontend(arg: String)
    /// Pass <arg> to the C/C++/Objective-C compiler
    /// Flags: FrontendOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <arg>
    case Xcc(arg: String)
    /// Pass <arg> to Clang when it is used for linking.
    /// Flags: HelpHidden
    /// Meta var name: <arg>
    case Xclang_linker(arg: String)
    /// Pass <arg> to LLVM.
    /// Flags: FrontendOption, HelpHidden
    /// Meta var name: <arg>
    case Xllvm(arg: String)
    /// The directory that holds the compiler resource files
    /// Flags: ArgumentIsPath, FrontendOption, HelpHidden, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: </usr/lib/swift>
    case resource_dir(arg: String)
    /// Generate code for the given target <triple>, such as x86_64-apple-macos10.9
    /// Flags: FrontendOption, ModuleInterfaceOption, ModuleWrapOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    /// Meta var name: <triple>
    case target(arg: String)
    /// Flags: FrontendOption
    /// Alias of: target
    case target_legacy_spelling(arg: String)
    /// Print target information for the given target <triple>, such as x86_64-apple-macos10.9
    /// Flags: FrontendOption
    /// Meta var name: <triple>
    case print_target_info
    /// Generate code for a particular CPU variant
    /// Flags: FrontendOption, ModuleInterfaceOption
    case target_cpu(arg: String)
    /// Generate 'zippered' code for macCatalyst that can run on the specified variant target triple in addition to the main -target triple
    /// Flags: FrontendOption, ModuleInterfaceOption
    case target_variant(arg: String)
    /// Separately set the target we should use for internal Clang instance
    /// Flags: FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption, SwiftSynthesizeInterfaceOption
    case clang_target(arg: String)
    /// Disable a separately specified target triple for Clang instance to use
    /// Flags: NewDriverOnlyOption
    case disable_clang_target
    /// Emit remark describing why compilation may depend on a module with a given name.
    /// Flags: NewDriverOnlyOption
    case explain_module_dependency(arg: String)
    /// Emit remarks describing every possible dependency path that explains why compilation may depend on a module with a given name.
    /// Flags: NewDriverOnlyOption
    case explain_module_dependency_detailed(arg: String)
    /// Instead of linker-load directives, have the driver specify all link dependencies on the linker invocation. Requires '-explicit-module-build'.
    /// Flags: NewDriverOnlyOption
    case explicit_auto_linking
    /// Require inlinable code with no '@available' attribute to back-deploy to this version of the '-target' OS
    /// Flags: FrontendOption, ModuleInterfaceOption
    case min_inlining_target_version(arg: String)
    /// Specify the minimum runtime version to build force on non-Darwin systems
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case min_runtime_version(arg: String)
    /// Generate instrumented code to collect execution counts
    /// Flags: FrontendOption, NoInteractiveOption
    case profile_generate
    /// Emit extra debug info (DWARF discriminators) to make sampling-based profiling more accurate
    /// Flags: FrontendOption, NewDriverOnlyOption, NoInteractiveOption
    case debug_info_for_profiling
    /// Supply a profdata file to enable profile-guided optimization
    /// Flags: ArgumentIsPath, FrontendOption, NoInteractiveOption
    /// Meta var name: <profdata>
    case profile_use(args: [String])
    /// Generate coverage data for use with profiled execution counts
    /// Flags: FrontendOption, NoInteractiveOption
    case profile_coverage_mapping
    /// Supply sampling-based profiling data from llvm-profdata to enable profile-guided optimization
    /// Flags: ArgumentIsPath, FrontendOption, NewDriverOnlyOption, NoInteractiveOption
    /// Meta var name: <profile data>
    case profile_sample_use(arg: String)
    /// Embed LLVM IR bitcode as data
    /// Flags: FrontendOption, NoInteractiveOption
    case embed_bitcode
    /// Embed placeholder LLVM IR data as a marker
    /// Flags: FrontendOption, NoInteractiveOption
    case embed_bitcode_marker
    /// Allows this module's internal API to be accessed for testing
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case enable_testing
    /// Allows this module's internal and private API to be accessed
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case enable_private_imports
    /// Turn on runtime checks for erroneous behavior.
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <check>
    case sanitize_EQ(args: [String])
    /// Specify which sanitizer runtime checks (see -sanitize=) will generate instrumentation that allows error recovery. Listed checks should be comma separated. Default behavior is to not allow error recovery.
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <check>
    case sanitize_recover_EQ(args: [String])
    /// When using AddressSanitizer enable ODR indicator globals to avoid false ODR violation reports in partially sanitized programs at the cost of an increase in binary size
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption
    case sanitize_address_use_odr_indicator
    /// Specify the type of coverage instrumentation for Sanitizers and additional options separated by commas
    /// Flags: FrontendOption, NoInteractiveOption
    /// Meta var name: <type>
    case sanitize_coverage_EQ(args: [String])
    /// Link against the Sanitizers stable ABI.
    /// Flags: FrontendOption, NoInteractiveOption
    case sanitize_stable_abi_EQ
    /// Scan dependencies of the given Swift sources
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case scan_dependencies
    /// Emit a JSON file including all supported compiler features
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, NoInteractiveOption
    /// Other options: ModeOpt
    case emit_supported_features
    /// Enable cross-module incremental build metadata and driver scheduling for Swift modules
    /// Flags: FrontendOption
    case enable_incremental_imports
    /// Disable cross-module incremental build metadata and driver scheduling for Swift modules
    /// Flags: FrontendOption
    case disable_incremental_imports
    /// Produce index data for a source file
    /// Flags: DoesNotAffectIncrementalBuild, NoInteractiveOption
    /// Other options: ModeOpt
    case index_file
    /// Produce index data for file <path>
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, NoInteractiveOption
    /// Meta var name: <path>
    case index_file_path(arg: String)
    /// Store indexing data to <path>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption
    /// Meta var name: <path>
    case index_store_path(arg: String)
    /// Use <path> as the output path in the produced index data.
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption
    /// Meta var name: <path>
    case index_unit_output_path(arg: String)
    /// Avoid indexing clang modules (pcms)
    /// Flags: FrontendOption
    case index_ignore_clang_modules
    /// Include local definitions/references in the produced index data.
    /// Flags: FrontendOption
    case index_include_locals
    /// Avoid indexing system modules
    /// Flags: NoInteractiveOption
    case index_ignore_system_modules
    /// Enforce law of exclusivity
    /// Flags: FrontendOption, ModuleInterfaceOption
    /// Meta var name: <enforcement>
    case enforce_exclusivity_EQ(arg: String)
    /// Resolve file paths relative to the specified directory
    /// Meta var name: <path>
    case working_directory(arg: String)
    /// Alias of: working_directory
    case working_directory_EQ(arg: String)
    /// Module version specified from Swift module authors
    /// Flags: FrontendOption, ModuleInterfaceOption, NewDriverOnlyOption
    /// Meta var name: <vers>
    case user_module_version(arg: String)
    /// Module names that are allowed to import this module
    /// Flags: FrontendOption, ModuleInterfaceOption, NewDriverOnlyOption
    /// Meta var name: <vers>
    case allowable_client(arg: String)
    /// Add directory to VFS overlay file
    /// Flags: ArgumentIsPath, FrontendOption
    case vfsoverlay(arg: String)
    /// Alias of: vfsoverlay
    case vfsoverlay_EQ(arg: String)
    /// Link compatibility library for Swift runtime version, or 'none'
    /// Flags: FrontendOption
    case runtime_compatibility_version(arg: String)
    /// Do not use autolinking for runtime compatibility libraries
    /// Flags: FrontendOption
    case disable_autolinking_runtime_compatibility
    /// Do not use autolinking for the dynamic replacement runtime compatibility library
    /// Flags: FrontendOption
    case disable_autolinking_runtime_compatibility_dynamic_replacements
    /// Do not use autolinking for the concurrency runtime compatibility library
    /// Flags: FrontendOption
    case disable_autolinking_runtime_compatibility_concurrency
    /// Enable autolinking for the bytecode layouts runtime compatibility library
    /// Flags: FrontendOption
    case enable_autolinking_runtime_compatibility_bytecode_layouts
    /// Emit a symbol graph
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    case emit_symbol_graph
    /// Emit a symbol graph to directory <dir>
    /// Flags: ArgumentIsPath, CacheInvariant, FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <dir>
    case emit_symbol_graph_dir(arg: String)
    /// Include symbols with this access level or more when emitting a symbol graph
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <level>
    case symbol_graph_minimum_access_level(arg: String)
    /// Pretty-print the output JSON
    /// Flags: SwiftSymbolGraphExtractOption
    case pretty_print
    /// Emit 'swift.extension' symbols for extensions to external types instead of directly associating members and conformances with the extended nominal when generating symbol graphs
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput, SwiftSymbolGraphExtractOption
    case emit_extension_block_symbols
    /// Directly associate members and conformances with the extended nominal when generating symbol graphs instead of emitting 'swift.extension' symbols for extensions to external types
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput, SwiftSymbolGraphExtractOption
    case omit_extension_block_symbols
    /// Also print the declarations synthesized for any Clang submodules
    /// Flags: NoDriverOption, SwiftSynthesizeInterfaceOption
    case include_submodules
    /// Always print fully qualified type names
    /// Flags: NoDriverOption, SwiftSynthesizeInterfaceOption
    case print_fully_qualified_types
    /// Output directory
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption
    /// Meta var name: <dir>
    case output_dir(arg: String)
    /// Allow reexporting symbols from the provided modules if they are themselves exported from the main module. This is a comma separated list of module names.
    /// Flags: NoDriverOption, SwiftSymbolGraphExtractOption
    case experimental_allowed_reexported_modules(args: [String])
    /// Skip members inherited through classes or default implementations
    /// Flags: NoDriverOption, SwiftSymbolGraphExtractOption
    case skip_synthesized_members
    /// Include symbols with this access level or more
    /// Flags: NoDriverOption, SwiftSymbolGraphExtractOption
    /// Meta var name: <level>
    case minimum_access_level(arg: String)
    /// Skip emitting doc comments for members inherited through classes or default implementations
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput, SwiftSymbolGraphExtractOption
    case skip_inherited_docs
    /// Add symbols with SPI information to the symbol graph
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput, SwiftSymbolGraphExtractOption
    case include_spi_symbols
    /// Skip emitting symbols that are implementations of protocol requirements or inherited from protocol extensions
    /// Flags: FrontendOption, HelpHidden, NoInteractiveOption, SupplementaryOutput, SwiftSymbolGraphExtractOption
    case skip_protocol_implementations
    /// Dump SDK content to JSON file
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case dump_sdk
    /// Compare SDK content in JSON file and generate migration script
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case generate_migration_script
    /// Diagnose SDK content in JSON file
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case diagnose_sdk
    /// Deserialize diff items in a JSON file
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case deserialize_diff
    /// Deserialize sdk digester in a JSON file
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case deserialize_sdk
    /// Find USR for decls by given condition
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case find_usr
    /// Generate name correction template
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case generate_name_correction
    /// Generate an empty baseline
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case generate_empty_baseline
    /// Use empty baseline for diagnostics
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case empty_baseline
    /// the file containing USRs of removed decls that the digester should ignore
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <path>
    case ignored_usrs(arg: String)
    /// SPI group name to not diagnose about
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case ignore_spi_groups(arg: String)
    /// File containing a new-line separated list of protocol names
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <path>
    case protocol_requirement_allow_list(arg: String)
    /// The SDK contents under comparison
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <path>
    case input_paths(arg: String)
    /// Print compiler style diagnostics to stderr.
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case compiler_style_diags
    /// Always treat ABI checker issues as errors
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case error_on_abi_breakage
    /// Print output in JSON format.
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case json
    /// Avoid serializing the file paths of SDK nodes.
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case avoid_location
    /// Filter nodes with the given location.
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <location>
    case location(arg: String)
    /// Avoid serializing the arguments for invoking the tool.
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case avoid_tool_args
    /// Dumping ABI interface
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case abi
    /// Only include APIs defined from Swift source
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case swift_only
    /// Skip OS related diagnostics
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case disable_os_checks
    /// Skip diagnosing removal of deprecated symbols
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case disable_remove_deprecated_check
    /// Diagnosing removal of deprecated symbols
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case enable_remove_deprecated_check
    /// Print module names in diagnostics
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case print_module
    /// Dump Json suitable for generating migration script
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case migrator
    /// Abort if a module failed to load
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case abort_on_module_fail
    /// Don't exit with a nonzero status if errors are emitted
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case disable_fail_on_error
    /// Dumping information for debug purposes
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    case debug_mapping
    /// add a directory to the baseline framework search path
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case BF(arg: String)
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    /// Alias of: BF
    case BF_EQ(arg: String)
    /// add a module for baseline input
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case BI(arg: String)
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    /// Alias of: BI
    case BI_EQ(arg: String)
    /// add a directory to the clang importer system framework search path
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case iframework(arg: String)
    /// The path to the Json file that we should use as the baseline
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case baseline_path(arg: String)
    /// The path to a directory containing baseline files: macos.json, iphoneos.json, appletvos.json, watchos.json, and iosmac.json
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case baseline_dir(arg: String)
    /// An allowlist of breakages to not complain about
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case breakage_allowlist_path(arg: String)
    /// path to the baseline SDK to import frameworks
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case bsdk(arg: String)
    /// File containing a new-line separated list of modules
    /// Flags: ArgumentIsPath, NoDriverOption, SwiftAPIDigesterOption
    case module_list_file(arg: String)
    /// Names of modules
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <name>
    case module(arg: String)
    /// Prefer loading these modules via interface
    /// Flags: NoDriverOption, SwiftAPIDigesterOption
    /// Meta var name: <name>
    case use_interface_for_module(arg: String)
    /// Load LLVM pass plugin from a dynamic shared object file.
    /// Flags: ArgumentIsPath, FrontendOption
    /// Meta var name: <path>
    case load_pass_plugin_EQ(arg: String)
    /// Write the job graph as a graphviz file
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden, NewDriverOnlyOption
    case driver_print_graphviz
    /// Prebuild module dependencies to make them explicit
    /// Flags: HelpHidden, NewDriverOnlyOption
    case driver_explicit_module_build
    /// Re-use/validate prior build dependency scan artifacts
    /// Flags: HelpHidden, NewDriverOnlyOption
    case incremental_dependency_scan
    /// Prebuild module dependencies to make them explicit
    /// Flags: HelpHidden, NewDriverOnlyOption
    /// Alias of: driver_explicit_module_build
    case driver_experimental_explicit_module_build
    /// Use calls to `swift-frontend -scan-dependencies` instead of dedicated dependency scanning library
    /// Flags: HelpHidden, NewDriverOnlyOption
    case driver_scan_dependencies_non_lib
    /// Always rebuild module dependencies
    /// Flags: HelpHidden, NewDriverOnlyOption
    case always_rebuild_module_dependencies
    /// Emit warnings for any provided options which are unused by the driver
    /// Flags: HelpHidden, NewDriverOnlyOption
    case driver_warn_unused_options
    /// Emit module files as a distinct job
    /// Flags: HelpHidden, NewDriverOnlyOption
    case emit_module_separately
    /// Force using merge-module as the incremental build mode
    /// Flags: HelpHidden, NewDriverOnlyOption
    case no_emit_module_separately
    /// Emit module files as a distinct job in wmo builds
    /// Flags: HelpHidden, NewDriverOnlyOption
    case emit_module_separately_WMO
    /// Force emitting the swiftmodule in the same job in wmo builds
    /// Flags: HelpHidden, NewDriverOnlyOption
    case no_emit_module_separately_WMO
    /// Emit a serialized diagnostics file for the emit-module task to <path>
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_serialize_diagnostics_path(arg: String)
    /// Emit a discovered dependencies file for the emit-module task to <path>
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_module_dependencies_path(arg: String)
    /// Emit parseable-output from swift-frontend jobs instead of from the driver
    /// Flags: CacheInvariant, HelpHidden, NewDriverOnlyOption
    case use_frontend_parseable_output
    /// Print the result of module dependency scanning after external module resolution to output
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden, NewDriverOnlyOption
    case print_explicit_dependency_graph
    /// Specify the explicit dependency graph output format to either 'json' or 'dot'
    /// Flags: DoesNotAffectIncrementalBuild, HelpHidden, NewDriverOnlyOption
    case explicit_dependency_graph_format(arg: String)
    /// Print the result of module dependency scanning to output
    /// Flags: HelpHidden, NewDriverOnlyOption
    case print_preprocessed_explicit_dependency_graph
    /// Emit a baseline file for the module using the API digester
    /// Flags: NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    case emit_digester_baseline
    /// Emit a baseline file for the module to <path> using the API digester
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, NoInteractiveOption, SupplementaryOutput
    /// Meta var name: <path>
    case emit_digester_baseline_path(arg: String)
    /// Compare the built module to the baseline at <path> and diagnose breaking changes using the API digester
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, NoInteractiveOption
    /// Meta var name: <path>
    case compare_to_baseline_path(arg: String)
    /// Serialize breaking changes found by the API digester to <path>
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, NoInteractiveOption
    /// Meta var name: <path>
    case serialize_breaking_changes_path(arg: String)
    /// The path to a list of permitted breaking changes the API digester should ignore
    /// Flags: ArgumentIsPath, NewDriverOnlyOption, NoInteractiveOption
    /// Meta var name: <path>
    case digester_breakage_allowlist_path(arg: String)
    /// Whether the API digester should run in API or ABI mode (defaults to API checking)
    /// Flags: NewDriverOnlyOption, NoInteractiveOption
    /// Meta var name: <api|abi>
    case digester_mode(arg: String)
    /// Do not link in the Swift language startup routines
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoInteractiveOption
    case nostartfiles
    /// Specify a directory where the clang importer and clang linker can find headers and libraries
    /// Flags: ArgumentIsPath, HelpHidden, NewDriverOnlyOption
    /// Meta var name: <path>
    case gcc_toolchain(arg: String)
    /// Enables swift driver to construct swift-frontend invocations using -direct-clang-cc1-module-build
    /// Flags: FrontendOption, HelpHidden, NewDriverOnlyOption
    case experimental_clang_importer_direct_cc1_scan
    /// Enable compiler caching
    /// Flags: FrontendOption, NewDriverOnlyOption
    case cache_compile_job
    /// Show remarks for compiler caching
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption
    case cache_remarks
    /// Skip loading the compilation result from cache
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption
    case cache_disable_replay
    /// Path to CAS
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption
    /// Meta var name: <path>
    case cas_path(arg: String)
    /// Path to CAS Plugin
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption
    /// Meta var name: <path>
    case cas_plugin_path(arg: String)
    /// Option pass to CAS Plugin
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption
    /// Meta var name: <name>=<option>
    case cas_plugin_option(arg: String)
    /// Specifies the Clang dependency scanner module cache path
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    case clang_scanner_module_cache_path(arg: String)
    /// Remap paths reported by dependency scanner
    /// Flags: FrontendOption, NewDriverOnlyOption
    /// Meta var name: <prefix=replacement>
    case scanner_prefix_map(arg: String)
    /// Remap paths within SDK reported by dependency scanner
    /// Flags: NewDriverOnlyOption
    /// Meta var name: <path>
    case scanner_prefix_map_sdk(arg: String)
    /// Remap paths within toolchain directory reported by dependency scanner
    /// Flags: NewDriverOnlyOption
    /// Meta var name: <path>
    case scanner_prefix_map_toolchain(arg: String)
    /// Remap paths when replaying outputs from cache
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <prefix=replacement>
    case cache_replay_prefix_map(arg: String)
    /// Add directory to the plugin search path
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption
    /// Other groups: Group<plugin_search_Group>
    case plugin_path(arg: String)
    /// Add directory to the plugin search path with a plugin server executable
    /// Flags: ArgumentIsPath, FrontendOption, SwiftAPIDigesterOption, SwiftSymbolGraphExtractOption
    /// Meta var name: <path>#<plugin-server-path>
    /// Other groups: Group<plugin_search_Group>
    case external_plugin_path(arg: String)
    /// Enable using CASBackend for object file output
    /// Flags: FrontendOption, NoDriverOption
    case cas_backend
    /// CASBackendMode for output kind
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: native|casid|verify
    case cas_backend_mode(arg: String)
    /// Emit .casid file next to object file when CAS Backend is enabled
    /// Flags: FrontendOption, NoDriverOption
    case cas_emit_casid_file
    /// Path to a dynamic library containing compiler plugins such as macros
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <path>
    /// Other groups: Group<plugin_search_Group>
    case load_plugin_library(arg: String)
    /// Path to a compiler plugin executable and a comma-separated list of module names where the macro types are declared
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <path>#<module-names>
    /// Other groups: Group<plugin_search_Group>
    case load_plugin_executable(arg: String)
    /// Path to resolved plugin configuration and a comma-separated list of module names where the macro types are declared. Library path and exectuable path can be empty if not used
    /// Flags: ArgumentIsPath, DoesNotAffectIncrementalBuild, FrontendOption
    /// Meta var name: <library-path>#<executable-path>#<module-names>
    /// Other groups: Group<plugin_search_Group>
    case load_resolved_plugin(arg: String)
    /// Path to dynamic library plugin server
    /// Flags: ArgumentIsPath, FrontendOption
    case in_process_plugin_server_path(arg: String)
    /// Disable using the sandbox when executing subprocesses
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption
    case disable_sandbox

    private var flags: [String] {
        switch self {
        case .driver_print_actions:
            return ["-driver-print-actions"]
        case .driver_print_output_file_map:
            return ["-driver-print-output-file-map"]
        case .driver_print_derived_output_file_map:
            return ["-driver-print-derived-output-file-map"]
        case .driver_print_bindings:
            return ["-driver-print-bindings"]
        case .driver_print_jobs:
            return ["-driver-print-jobs"]
        case ._HASH_HASH_HASH:
            return ["-###"]
        case .driver_skip_execution:
            return ["-driver-skip-execution"]
        case .driver_use_frontend_path(let arg):
            return ["-driver-use-frontend-path", arg]
        case .driver_show_incremental:
            return ["-driver-show-incremental"]
        case .driver_show_job_lifecycle:
            return ["-driver-show-job-lifecycle"]
        case .driver_use_filelists:
            return ["-driver-use-filelists"]
        case .driver_filelist_threshold(let arg):
            return ["-driver-filelist-threshold", arg]
        case .driver_filelist_threshold_EQ(let arg):
            return ["-driver-filelist-threshold=\(arg)"]
        case .driver_batch_seed(let arg):
            return ["-driver-batch-seed", arg]
        case .driver_batch_count(let arg):
            return ["-driver-batch-count", arg]
        case .driver_batch_size_limit(let arg):
            return ["-driver-batch-size-limit", arg]
        case .driver_force_response_files:
            return ["-driver-force-response-files"]
        case .driver_always_rebuild_dependents:
            return ["-driver-always-rebuild-dependents"]
        case .enable_only_one_dependency_file:
            return ["-enable-only-one-dependency-file"]
        case .disable_only_one_dependency_file:
            return ["-disable-only-one-dependency-file"]
        case .driver_verify_fine_grained_dependency_graph_after_every_import:
            return ["-driver-verify-fine-grained-dependency-graph-after-every-import"]
        case .verify_incremental_dependencies:
            return ["-verify-incremental-dependencies"]
        case .strict_implicit_module_context:
            return ["-strict-implicit-module-context"]
        case .no_strict_implicit_module_context:
            return ["-no-strict-implicit-module-context"]
        case .compiler_assertions:
            return ["-compiler-assertions"]
        case .validate_clang_modules_once:
            return ["-validate-clang-modules-once"]
        case .clang_build_session_file(let arg):
            return ["-clang-build-session-file", arg]
        case .disallow_forwarding_driver:
            return ["-disallow-use-new-driver"]
        case .driver_emit_fine_grained_dependency_dot_file_after_every_import:
            return ["-driver-emit-fine-grained-dependency-dot-file-after-every-import"]
        case .emit_fine_grained_dependency_sourcefile_dot_files:
            return ["-emit-fine-grained-dependency-sourcefile-dot-files"]
        case .driver_mode(let arg):
            return ["--driver-mode=\(arg)"]
        case .help:
            return ["-help"]
        case .h:
            return ["-h"]
        case .help_hidden:
            return ["-help-hidden"]
        case .v:
            return ["-v"]
        case .version:
            return ["-version"]
        case .parseable_output:
            return ["-parseable-output"]
        case .windows_sdk_root(let arg):
            return ["-windows-sdk-root", arg]
        case .windows_sdk_version(let arg):
            return ["-windows-sdk-version", arg]
        case .visualc_tools_root(let arg):
            return ["-visualc-tools-root", arg]
        case .visualc_tools_version(let arg):
            return ["-visualc-tools-version", arg]
        case .sysroot(let arg):
            return ["-sysroot", arg]
        case .o(let arg):
            return ["-o", arg]
        case .j(let arg):
            return ["-j", arg]
        case .sdk(let arg):
            return ["-sdk", arg]
        case .swift_version(let arg):
            return ["-swift-version", arg]
        case .language_mode(let arg):
            return ["-language-mode", arg]
        case .package_description_version(let arg):
            return ["-package-description-version", arg]
        case .swiftinterface_compiler_version(let arg):
            return ["-interface-compiler-version", arg]
        case .tools_directory(let arg):
            return ["-tools-directory", arg]
        case .D(let arg):
            return ["-D", arg]
        case .e(let arg):
            return ["-e", arg]
        case .F(let arg):
            return ["-F", arg]
        case .F_EQ(let arg):
            return ["-F=\(arg)"]
        case .Fsystem(let arg):
            return ["-Fsystem", arg]
        case .I(let arg):
            return ["-I", arg]
        case .I_EQ(let arg):
            return ["-I=\(arg)"]
        case .Isystem(let arg):
            return ["-Isystem", arg]
        case .import_underlying_module:
            return ["-import-underlying-module"]
        case .import_objc_header(let arg):
            return ["-import-objc-header", arg]
        case .import_bridging_header(let arg):
            return ["-import-bridging-header", arg]
        case .import_pch(let arg):
            return ["-import-pch", arg]
        case .pch_output_dir(let arg):
            return ["-pch-output-dir", arg]
        case .auto_bridging_header_chaining:
            return ["-auto-bridging-header-chaining"]
        case .no_auto_bridging_header_chaining:
            return ["-no-auto-bridging-header-chaining"]
        case .incremental:
            return ["-incremental"]
        case .nostdimport:
            return ["-nostdimport"]
        case .nostdlibimport:
            return ["-nostdlibimport"]
        case .output_file_map(let arg):
            return ["-output-file-map", arg]
        case .output_file_map_EQ(let arg):
            return ["-output-file-map=\(arg)"]
        case .save_temps:
            return ["-save-temps"]
        case .driver_time_compilation:
            return ["-driver-time-compilation"]
        case .stats_output_dir(let arg):
            return ["-stats-output-dir", arg]
        case .print_zero_stats:
            return ["-print-zero-stats"]
        case .fine_grained_timers:
            return ["-fine-grained-timers"]
        case .trace_stats_events:
            return ["-trace-stats-events"]
        case .experimental_skip_non_inlinable_function_bodies:
            return ["-experimental-skip-non-inlinable-function-bodies"]
        case .experimental_skip_non_inlinable_function_bodies_without_types:
            return ["-experimental-skip-non-inlinable-function-bodies-without-types"]
        case .profile_stats_events:
            return ["-profile-stats-events"]
        case .profile_stats_entities:
            return ["-profile-stats-entities"]
        case .emit_dependencies:
            return ["-emit-dependencies"]
        case .track_system_dependencies:
            return ["-track-system-dependencies"]
        case .emit_loaded_module_trace:
            return ["-emit-loaded-module-trace"]
        case .emit_loaded_module_trace_path(let arg):
            return ["-emit-loaded-module-trace-path", arg]
        case .emit_loaded_module_trace_path_EQ(let arg):
            return ["-emit-loaded-module-trace-path=\(arg)"]
        case .emit_cross_import_remarks:
            return ["-Rcross-import"]
        case .remark_loading_module:
            return ["-Rmodule-loading"]
        case .remark_module_recovery:
            return ["-Rmodule-recovery"]
        case .remark_module_api_import:
            return ["-Rmodule-api-import"]
        case .remark_macro_loading:
            return ["-Rmacro-loading"]
        case .remark_indexing_system_module:
            return ["-Rindexing-system-module"]
        case .remark_skip_explicit_interface_build:
            return ["-Rskip-explicit-interface-build"]
        case .remark_module_serialization:
            return ["-Rmodule-serialization"]
        case .emit_tbd:
            return ["-emit-tbd"]
        case .emit_tbd_path(let arg):
            return ["-emit-tbd-path", arg]
        case .emit_tbd_path_EQ(let arg):
            return ["-emit-tbd-path=\(arg)"]
        case .embed_tbd_for_module(let arg):
            return ["-embed-tbd-for-module", arg]
        case .serialize_diagnostics:
            return ["-serialize-diagnostics"]
        case .serialize_diagnostics_path(let arg):
            return ["-serialize-diagnostics-path", arg]
        case .serialize_diagnostics_path_EQ(let arg):
            return ["-serialize-diagnostics-path=\(arg)"]
        case .color_diagnostics:
            return ["-color-diagnostics"]
        case .no_color_diagnostics:
            return ["-no-color-diagnostics"]
        case .debug_diagnostic_names:
            return ["-debug-diagnostic-names"]
        case .print_diagnostic_groups:
            return ["-print-diagnostic-groups"]
        case .print_educational_notes:
            return ["-print-educational-notes"]
        case .diagnostic_style(let arg):
            return ["-diagnostic-style", arg]
        case .diagnostic_style_EQ(let arg):
            return ["-diagnostic-style=\(arg)"]
        case .locale(let arg):
            return ["-locale", arg]
        case .localization_path(let arg):
            return ["-localization-path", arg]
        case .module_cache_path(let arg):
            return ["-module-cache-path", arg]
        case .enable_library_evolution:
            return ["-enable-library-evolution"]
        case .require_explicit_availability:
            return ["-require-explicit-availability"]
        case .require_explicit_availability_EQ(let arg):
            return ["-require-explicit-availability=\(arg)"]
        case .require_explicit_availability_target(let arg):
            return ["-require-explicit-availability-target", arg]
        case .require_explicit_sendable:
            return ["-require-explicit-sendable"]
        case .define_availability(let arg):
            return ["-define-availability", arg]
        case .check_api_availability_only:
            return ["-check-api-availability-only"]
        case .unavailable_decl_optimization_EQ(let arg):
            return ["-unavailable-decl-optimization=\(arg)"]
        case .define_enabled_availability_domain(let arg):
            return ["-define-enabled-availability-domain", arg]
        case .define_disabled_availability_domain(let arg):
            return ["-define-disabled-availability-domain", arg]
        case .define_dynamic_availability_domain(let arg):
            return ["-define-dynamic-availability-domain", arg]
        case .experimental_package_bypass_resilience:
            return ["-experimental-package-bypass-resilience"]
        case .experimental_allow_non_resilient_access:
            return ["-experimental-allow-non-resilient-access"]
        case .allow_non_resilient_access:
            return ["-allow-non-resilient-access"]
        case .library_level(let arg):
            return ["-library-level", arg]
        case .library_level_EQ(let arg):
            return ["-library-level=\(arg)"]
        case .module_name(let arg):
            return ["-module-name", arg]
        case .project_name(let arg):
            return ["-project-name", arg]
        case .module_name_EQ(let arg):
            return ["-module-name=\(arg)"]
        case .module_alias(let arg):
            return ["-module-alias", arg]
        case .module_link_name(let arg):
            return ["-module-link-name", arg]
        case .module_link_name_EQ(let arg):
            return ["-module-link-name=\(arg)"]
        case .autolink_force_load:
            return ["-autolink-force-load"]
        case .module_abi_name(let arg):
            return ["-module-abi-name", arg]
        case .package_name(let arg):
            return ["-package-name", arg]
        case .export_as(let arg):
            return ["-export-as", arg]
        case .public_module_name(let arg):
            return ["-public-module-name", arg]
        case .emit_module:
            return ["-emit-module"]
        case .emit_module_path(let arg):
            return ["-emit-module-path", arg]
        case .emit_module_path_EQ(let arg):
            return ["-emit-module-path=\(arg)"]
        case .emit_variant_module_path(let arg):
            return ["-emit-variant-module-path", arg]
        case .emit_module_summary:
            return ["-emit-module-summary"]
        case .emit_module_summary_path(let arg):
            return ["-emit-module-summary-path", arg]
        case .emit_module_interface:
            return ["-emit-module-interface"]
        case .emit_module_interface_path(let arg):
            return ["-emit-module-interface-path", arg]
        case .emit_variant_module_interface_path(let arg):
            return ["-emit-variant-module-interface-path", arg]
        case .emit_private_module_interface_path(let arg):
            return ["-emit-private-module-interface-path", arg]
        case .emit_variant_private_module_interface_path(let arg):
            return ["-emit-variant-private-module-interface-path", arg]
        case .emit_package_module_interface_path(let arg):
            return ["-emit-package-module-interface-path", arg]
        case .emit_variant_package_module_interface_path(let arg):
            return ["-emit-variant-package-module-interface-path", arg]
        case .verify_emitted_module_interface:
            return ["-verify-emitted-module-interface"]
        case .no_verify_emitted_module_interface:
            return ["-no-verify-emitted-module-interface"]
        case .avoid_emit_module_source_info:
            return ["-avoid-emit-module-source-info"]
        case .emit_module_source_info_path(let arg):
            return ["-emit-module-source-info-path", arg]
        case .emit_variant_module_source_info_path(let arg):
            return ["-emit-variant-module-source-info-path", arg]
        case .emit_parseable_module_interface:
            return ["-emit-parseable-module-interface"]
        case .emit_parseable_module_interface_path(let arg):
            return ["-emit-parseable-module-interface-path", arg]
        case .emit_const_values:
            return ["-emit-const-values"]
        case .emit_const_values_path(let arg):
            return ["-emit-const-values-path", arg]
        case .emit_api_descriptor:
            return ["-emit-api-descriptor"]
        case .emit_api_descriptor_path(let arg):
            return ["-emit-api-descriptor-path", arg]
        case .emit_variant_api_descriptor_path(let arg):
            return ["-emit-variant-api-descriptor-path", arg]
        case .emit_objc_header:
            return ["-emit-objc-header"]
        case .emit_objc_header_path(let arg):
            return ["-emit-objc-header-path", arg]
        case .emit_clang_header_nonmodular_includes:
            return ["-emit-clang-header-nonmodular-includes"]
        case .emit_clang_header_path(let arg):
            return ["-emit-clang-header-path", arg]
        case .static:
            return ["-static"]
        case .import_cf_types:
            return ["-import-cf-types"]
        case .solver_memory_threshold(let arg):
            return ["-solver-memory-threshold", arg]
        case .solver_shrink_unsolved_threshold(let arg):
            return ["-solver-shrink-unsolved-threshold", arg]
        case .value_recursion_threshold(let arg):
            return ["-value-recursion-threshold", arg]
        case .disable_swift_bridge_attr:
            return ["-disable-swift-bridge-attr"]
        case .enable_bridging_pch:
            return ["-enable-bridging-pch"]
        case .disable_bridging_pch:
            return ["-disable-bridging-pch"]
        case .lto(let arg):
            return ["-lto=\(arg)"]
        case .lto_library(let arg):
            return ["-lto-library", arg]
        case .access_notes_path(let arg):
            return ["-access-notes-path", arg]
        case .access_notes_path_EQ(let arg):
            return ["-access-notes-path=\(arg)"]
        case .enable_experimental_forward_mode_differentiation:
            return ["-enable-experimental-forward-mode-differentiation"]
        case .enable_experimental_additive_arithmetic_derivation:
            return ["-enable-experimental-additive-arithmetic-derivation"]
        case .enable_experimental_concise_pound_file:
            return ["-enable-experimental-concise-pound-file"]
        case .enable_experimental_cxx_interop:
            return ["-enable-experimental-cxx-interop"]
        case .cxx_interoperability_mode(let arg):
            return ["-cxx-interoperability-mode=\(arg)"]
        case .experimental_c_foreign_reference_types:
            return ["-experimental-c-foreign-reference-types"]
        case .experimental_hermetic_seal_at_link:
            return ["-experimental-hermetic-seal-at-link"]
        case .experimental_package_interface_load:
            return ["-experimental-package-interface-load"]
        case .experimental_serialize_debug_info:
            return ["-experimental-serialize-debug-info"]
        case .suppress_warnings:
            return ["-suppress-warnings"]
        case .warnings_as_errors:
            return ["-warnings-as-errors"]
        case .Werror(let arg):
            return ["-Werror", arg]
        case .no_warnings_as_errors:
            return ["-no-warnings-as-errors"]
        case .Wwarning(let arg):
            return ["-Wwarning", arg]
        case .suppress_remarks:
            return ["-suppress-remarks"]
        case .continue_building_after_errors:
            return ["-continue-building-after-errors"]
        case .warn_swift3_objc_inference_complete:
            return ["-warn-swift3-objc-inference-complete"]
        case .warn_swift3_objc_inference_minimal:
            return ["-warn-swift3-objc-inference-minimal"]
        case .enable_actor_data_race_checks:
            return ["-enable-actor-data-race-checks"]
        case .disable_actor_data_race_checks:
            return ["-disable-actor-data-race-checks"]
        case .disable_dynamic_actor_isolation:
            return ["-disable-dynamic-actor-isolation"]
        case .enable_bare_slash_regex:
            return ["-enable-bare-slash-regex"]
        case .warn_implicit_overrides:
            return ["-warn-implicit-overrides"]
        case .warn_soft_deprecated:
            return ["-warn-soft-deprecated"]
        case .typo_correction_limit(let arg):
            return ["-typo-correction-limit", arg]
        case .warn_swift3_objc_inference:
            return ["-warn-swift3-objc-inference"]
        case .warn_concurrency:
            return ["-warn-concurrency"]
        case .strict_concurrency(let arg):
            return ["-strict-concurrency=\(arg)"]
        case .enable_experimental_feature(let arg):
            return ["-enable-experimental-feature", arg]
        case .disable_experimental_feature(let arg):
            return ["-disable-experimental-feature", arg]
        case .enable_upcoming_feature(let arg):
            return ["-enable-upcoming-feature", arg]
        case .disable_upcoming_feature(let arg):
            return ["-disable-upcoming-feature", arg]
        case .Rpass_EQ(let arg):
            return ["-Rpass=\(arg)"]
        case .Rpass_missed_EQ(let arg):
            return ["-Rpass-missed=\(arg)"]
        case .save_optimization_record:
            return ["-save-optimization-record"]
        case .save_optimization_record_EQ(let arg):
            return ["-save-optimization-record=\(arg)"]
        case .save_optimization_record_path(let arg):
            return ["-save-optimization-record-path", arg]
        case .save_optimization_record_passes(let arg):
            return ["-save-optimization-record-passes", arg]
        case .no_allocations:
            return ["-no-allocations"]
        case .enable_app_extension:
            return ["-application-extension"]
        case .enable_app_extension_library:
            return ["-application-extension-library"]
        case .libc(let arg):
            return ["-libc", arg]
        case .l(let arg):
            return ["-l", arg]
        case .framework(let arg):
            return ["-framework", arg]
        case .L(let arg):
            return ["-L", arg]
        case .L_EQ(let arg):
            return ["-L=\(arg)"]
        case .link_objc_runtime:
            return ["-link-objc-runtime"]
        case .no_link_objc_runtime:
            return ["-no-link-objc-runtime"]
        case .static_stdlib:
            return ["-static-stdlib"]
        case .no_static_stdlib:
            return ["-no-static-stdlib"]
        case .toolchain_stdlib_rpath:
            return ["-toolchain-stdlib-rpath"]
        case .no_toolchain_stdlib_rpath:
            return ["-no-toolchain-stdlib-rpath"]
        case .no_stdlib_rpath:
            return ["-no-stdlib-rpath"]
        case .static_executable:
            return ["-static-executable"]
        case .no_static_executable:
            return ["-no-static-executable"]
        case .use_ld(let arg):
            return ["-use-ld=\(arg)"]
        case .ld_path(let arg):
            return ["-ld-path=\(arg)"]
        case .Xlinker(let arg):
            return ["-Xlinker", arg]
        case .build_id(let arg):
            return ["-build-id", arg]
        case .build_id_EQ(let arg):
            return ["-build-id=\(arg)"]
        case .Onone:
            return ["-Onone"]
        case .O:
            return ["-O"]
        case .Osize:
            return ["-Osize"]
        case .Ounchecked:
            return ["-Ounchecked"]
        case .Oplayground:
            return ["-Oplayground"]
        case .ExperimentalPackageCMOAbortOnDeserializationFail:
            return ["-experimental-package-cmo-abort-on-deserialization-fail"]
        case .ExperimentalPackageCMO:
            return ["-experimental-package-cmo"]
        case .PackageCMO:
            return ["-package-cmo"]
        case .EnableDefaultCMO:
            return ["-enable-default-cmo"]
        case .EnableCMOEverything:
            return ["-enable-cmo-everything"]
        case .CrossModuleOptimization:
            return ["-cross-module-optimization"]
        case .disableCrossModuleOptimization:
            return ["-disable-cmo"]
        case .ExperimentalPerformanceAnnotations:
            return ["-experimental-performance-annotations"]
        case .RemoveRuntimeAsserts:
            return ["-remove-runtime-asserts"]
        case .AssumeSingleThreaded:
            return ["-assume-single-threaded"]
        case .g:
            return ["-g"]
        case .gnone:
            return ["-gnone"]
        case .gline_tables_only:
            return ["-gline-tables-only"]
        case .gdwarf_types:
            return ["-gdwarf-types"]
        case .debug_prefix_map(let arg):
            return ["-debug-prefix-map", arg]
        case .coverage_prefix_map(let arg):
            return ["-coverage-prefix-map", arg]
        case .file_prefix_map(let arg):
            return ["-file-prefix-map", arg]
        case .file_compilation_dir(let arg):
            return ["-file-compilation-dir", arg]
        case .debug_info_format(let arg):
            return ["-debug-info-format=\(arg)"]
        case .dwarf_version(let arg):
            return ["-dwarf-version=\(arg)"]
        case .prefix_serialized_debugging_options:
            return ["-prefix-serialized-debugging-options"]
        case .verify_debug_info:
            return ["-verify-debug-info"]
        case .debug_info_store_invocation:
            return ["-debug-info-store-invocation"]
        case .AssertConfig(let arg):
            return ["-assert-config", arg]
        case .use_tabs:
            return ["-use-tabs"]
        case .indent_switch_case:
            return ["-indent-switch-case"]
        case .in_place:
            return ["-in-place"]
        case .tab_width(let arg):
            return ["-tab-width", arg]
        case .indent_width(let arg):
            return ["-indent-width", arg]
        case .line_range(let arg):
            return ["-line-range", arg]
        case .update_code:
            return ["-update-code"]
        case .migrate_keep_objc_visibility:
            return ["-migrate-keep-objc-visibility"]
        case .disable_migrator_fixits:
            return ["-disable-migrator-fixits"]
        case .emit_remap_file_path(let arg):
            return ["-emit-remap-file-path", arg]
        case .emit_migrated_file_path(let arg):
            return ["-emit-migrated-file-path", arg]
        case .dump_migration_states_dir(let arg):
            return ["-dump-migration-states-dir", arg]
        case .api_diff_data_file(let arg):
            return ["-api-diff-data-file", arg]
        case .api_diff_data_dir(let arg):
            return ["-api-diff-data-dir", arg]
        case .dump_usr:
            return ["-dump-usr"]
        case .migrator_update_sdk:
            return ["-migrator-update-sdk"]
        case .migrator_update_swift:
            return ["-migrator-update-swift"]
        case .parse_as_library:
            return ["-parse-as-library"]
        case .parse_sil:
            return ["-parse-sil"]
        case .parse_stdlib:
            return ["-parse-stdlib"]
        case .enable_builtin_module:
            return ["-enable-builtin-module"]
        case .emit_object:
            return ["-emit-object"]
        case .emit_assembly:
            return ["-emit-assembly"]
        case .emit_bc:
            return ["-emit-bc"]
        case .emit_irgen:
            return ["-emit-irgen"]
        case .emit_ir:
            return ["-emit-ir"]
        case .emit_sil:
            return ["-emit-sil"]
        case .emit_silgen:
            return ["-emit-silgen"]
        case .emit_lowered_sil:
            return ["-emit-lowered-sil"]
        case .emit_sib:
            return ["-emit-sib"]
        case .emit_sibgen:
            return ["-emit-sibgen"]
        case .emit_imported_modules:
            return ["-emit-imported-modules"]
        case .emit_pcm:
            return ["-emit-pcm"]
        case .emit_executable:
            return ["-emit-executable"]
        case .emit_library:
            return ["-emit-library"]
        case .c:
            return ["-c"]
        case .S:
            return ["-S"]
        case .fixit_all:
            return ["-fixit-all"]
        case .parse:
            return ["-parse"]
        case .resolve_imports:
            return ["-resolve-imports"]
        case .typecheck:
            return ["-typecheck"]
        case .dump_parse:
            return ["-dump-parse"]
        case .emit_parse:
            return ["-emit-parse"]
        case .dump_ast:
            return ["-dump-ast"]
        case .dump_ast_format(let arg):
            return ["-dump-ast-format", arg]
        case .emit_ast:
            return ["-emit-ast"]
        case .dump_scope_maps(let arg):
            return ["-dump-scope-maps", arg]
        case .dump_availability_scopes:
            return ["-dump-availability-scopes"]
        case .dump_type_info:
            return ["-dump-type-info"]
        case .print_ast:
            return ["-print-ast"]
        case .print_ast_decl:
            return ["-print-ast-decl"]
        case .dump_pcm:
            return ["-dump-pcm"]
        case .repl:
            return ["-repl"]
        case .lldb_repl:
            return ["-lldb-repl"]
        case .deprecated_integrated_repl:
            return ["-deprecated-integrated-repl"]
        case .i:
            return ["-i"]
        case .whole_module_optimization:
            return ["-whole-module-optimization"]
        case .no_whole_module_optimization:
            return ["-no-whole-module-optimization"]
        case .enable_batch_mode:
            return ["-enable-batch-mode"]
        case .disable_batch_mode:
            return ["-disable-batch-mode"]
        case .wmo:
            return ["-wmo"]
        case .force_single_frontend_invocation:
            return ["-force-single-frontend-invocation"]
        case .num_threads(let arg):
            return ["-num-threads", arg]
        case .Xfrontend(let arg):
            return ["-Xfrontend", arg]
        case .Xcc(let arg):
            return ["-Xcc", arg]
        case .Xclang_linker(let arg):
            return ["-Xclang-linker", arg]
        case .Xllvm(let arg):
            return ["-Xllvm", arg]
        case .resource_dir(let arg):
            return ["-resource-dir", arg]
        case .target(let arg):
            return ["-target", arg]
        case .target_legacy_spelling(let arg):
            return ["--target=\(arg)"]
        case .print_target_info:
            return ["-print-target-info"]
        case .target_cpu(let arg):
            return ["-target-cpu", arg]
        case .target_variant(let arg):
            return ["-target-variant", arg]
        case .clang_target(let arg):
            return ["-clang-target", arg]
        case .disable_clang_target:
            return ["-disable-clang-target"]
        case .explain_module_dependency(let arg):
            return ["-explain-module-dependency", arg]
        case .explain_module_dependency_detailed(let arg):
            return ["-explain-module-dependency-detailed", arg]
        case .explicit_auto_linking:
            return ["-explicit-auto-linking"]
        case .min_inlining_target_version(let arg):
            return ["-target-min-inlining-version", arg]
        case .min_runtime_version(let arg):
            return ["-min-runtime-version", arg]
        case .profile_generate:
            return ["-profile-generate"]
        case .debug_info_for_profiling:
            return ["-debug-info-for-profiling"]
        case .profile_use(let args):
            let commaArg = args.joined(separator: ",")
            return ["-profile-use==\(commaArg)"]
        case .profile_coverage_mapping:
            return ["-profile-coverage-mapping"]
        case .profile_sample_use(let arg):
            return ["-profile-sample-use=\(arg)"]
        case .embed_bitcode:
            return ["-embed-bitcode"]
        case .embed_bitcode_marker:
            return ["-embed-bitcode-marker"]
        case .enable_testing:
            return ["-enable-testing"]
        case .enable_private_imports:
            return ["-enable-private-imports"]
        case .sanitize_EQ(let args):
            let commaArg = args.joined(separator: ",")
            return ["-sanitize==\(commaArg)"]
        case .sanitize_recover_EQ(let args):
            let commaArg = args.joined(separator: ",")
            return ["-sanitize-recover==\(commaArg)"]
        case .sanitize_address_use_odr_indicator:
            return ["-sanitize-address-use-odr-indicator"]
        case .sanitize_coverage_EQ(let args):
            let commaArg = args.joined(separator: ",")
            return ["-sanitize-coverage==\(commaArg)"]
        case .sanitize_stable_abi_EQ:
            return ["-sanitize-stable-abi"]
        case .scan_dependencies:
            return ["-scan-dependencies"]
        case .emit_supported_features:
            return ["-emit-supported-features"]
        case .enable_incremental_imports:
            return ["-enable-incremental-imports"]
        case .disable_incremental_imports:
            return ["-disable-incremental-imports"]
        case .index_file:
            return ["-index-file"]
        case .index_file_path(let arg):
            return ["-index-file-path", arg]
        case .index_store_path(let arg):
            return ["-index-store-path", arg]
        case .index_unit_output_path(let arg):
            return ["-index-unit-output-path", arg]
        case .index_ignore_clang_modules:
            return ["-index-ignore-clang-modules"]
        case .index_include_locals:
            return ["-index-include-locals"]
        case .index_ignore_system_modules:
            return ["-index-ignore-system-modules"]
        case .enforce_exclusivity_EQ(let arg):
            return ["-enforce-exclusivity=\(arg)"]
        case .working_directory(let arg):
            return ["-working-directory", arg]
        case .working_directory_EQ(let arg):
            return ["-working-directory=\(arg)"]
        case .user_module_version(let arg):
            return ["-user-module-version", arg]
        case .allowable_client(let arg):
            return ["-allowable-client", arg]
        case .vfsoverlay(let arg):
            return ["-vfsoverlay", arg]
        case .vfsoverlay_EQ(let arg):
            return ["-vfsoverlay=\(arg)"]
        case .runtime_compatibility_version(let arg):
            return ["-runtime-compatibility-version", arg]
        case .disable_autolinking_runtime_compatibility:
            return ["-disable-autolinking-runtime-compatibility"]
        case .disable_autolinking_runtime_compatibility_dynamic_replacements:
            return ["-disable-autolinking-runtime-compatibility-dynamic-replacements"]
        case .disable_autolinking_runtime_compatibility_concurrency:
            return ["-disable-autolinking-runtime-compatibility-concurrency"]
        case .enable_autolinking_runtime_compatibility_bytecode_layouts:
            return ["-enable-autolinking-runtime-compatibility-bytecode-layouts"]
        case .emit_symbol_graph:
            return ["-emit-symbol-graph"]
        case .emit_symbol_graph_dir(let arg):
            return ["-emit-symbol-graph-dir", arg]
        case .symbol_graph_minimum_access_level(let arg):
            return ["-symbol-graph-minimum-access-level", arg]
        case .pretty_print:
            return ["-pretty-print"]
        case .emit_extension_block_symbols:
            return ["-emit-extension-block-symbols"]
        case .omit_extension_block_symbols:
            return ["-omit-extension-block-symbols"]
        case .include_submodules:
            return ["-include-submodules"]
        case .print_fully_qualified_types:
            return ["-print-fully-qualified-types"]
        case .output_dir(let arg):
            return ["-output-dir", arg]
        case .experimental_allowed_reexported_modules(let args):
            let commaArg = args.joined(separator: ",")
            return ["-experimental-allowed-reexported-modules==\(commaArg)"]
        case .skip_synthesized_members:
            return ["-skip-synthesized-members"]
        case .minimum_access_level(let arg):
            return ["-minimum-access-level", arg]
        case .skip_inherited_docs:
            return ["-skip-inherited-docs"]
        case .include_spi_symbols:
            return ["-include-spi-symbols"]
        case .skip_protocol_implementations:
            return ["-skip-protocol-implementations"]
        case .dump_sdk:
            return ["-dump-sdk"]
        case .generate_migration_script:
            return ["-generate-migration-script"]
        case .diagnose_sdk:
            return ["-diagnose-sdk"]
        case .deserialize_diff:
            return ["-deserialize-diff"]
        case .deserialize_sdk:
            return ["-deserialize-sdk"]
        case .find_usr:
            return ["-find-usr"]
        case .generate_name_correction:
            return ["-generate-name-correction"]
        case .generate_empty_baseline:
            return ["-generate-empty-baseline"]
        case .empty_baseline:
            return ["-empty-baseline"]
        case .ignored_usrs(let arg):
            return ["-ignored-usrs", arg]
        case .ignore_spi_groups(let arg):
            return ["-ignore-spi-group", arg]
        case .protocol_requirement_allow_list(let arg):
            return ["-protocol-requirement-allow-list", arg]
        case .input_paths(let arg):
            return ["-input-paths", arg]
        case .compiler_style_diags:
            return ["-compiler-style-diags"]
        case .error_on_abi_breakage:
            return ["-error-on-abi-breakage"]
        case .json:
            return ["-json"]
        case .avoid_location:
            return ["-avoid-location"]
        case .location(let arg):
            return ["-location", arg]
        case .avoid_tool_args:
            return ["-avoid-tool-args"]
        case .abi:
            return ["-abi"]
        case .swift_only:
            return ["-swift-only"]
        case .disable_os_checks:
            return ["-disable-os-checks"]
        case .disable_remove_deprecated_check:
            return ["-disable-remove-deprecated-check"]
        case .enable_remove_deprecated_check:
            return ["-enable-remove-deprecated-check"]
        case .print_module:
            return ["-print-module"]
        case .migrator:
            return ["-migrator"]
        case .abort_on_module_fail:
            return ["-abort-on-module-fail"]
        case .disable_fail_on_error:
            return ["-disable-fail-on-error"]
        case .debug_mapping:
            return ["-debug-mapping"]
        case .BF(let arg):
            return ["-BF", arg]
        case .BF_EQ(let arg):
            return ["-BF=\(arg)"]
        case .BI(let arg):
            return ["-BI", arg]
        case .BI_EQ(let arg):
            return ["-BI=\(arg)"]
        case .iframework(let arg):
            return ["-iframework", arg]
        case .baseline_path(let arg):
            return ["-baseline-path", arg]
        case .baseline_dir(let arg):
            return ["-baseline-dir", arg]
        case .breakage_allowlist_path(let arg):
            return ["-breakage-allowlist-path", arg]
        case .bsdk(let arg):
            return ["-bsdk", arg]
        case .module_list_file(let arg):
            return ["-module-list-file", arg]
        case .module(let arg):
            return ["-module", arg]
        case .use_interface_for_module(let arg):
            return ["-use-interface-for-module", arg]
        case .load_pass_plugin_EQ(let arg):
            return ["-load-pass-plugin=\(arg)"]
        case .driver_print_graphviz:
            return ["-driver-print-graphviz"]
        case .driver_explicit_module_build:
            return ["-explicit-module-build"]
        case .incremental_dependency_scan:
            return ["-incremental-dependency-scan"]
        case .driver_experimental_explicit_module_build:
            return ["-experimental-explicit-module-build"]
        case .driver_scan_dependencies_non_lib:
            return ["-nonlib-dependency-scanner"]
        case .always_rebuild_module_dependencies:
            return ["-always-rebuild-module-dependencies"]
        case .driver_warn_unused_options:
            return ["-driver-warn-unused-options"]
        case .emit_module_separately:
            return ["-experimental-emit-module-separately"]
        case .no_emit_module_separately:
            return ["-no-emit-module-separately"]
        case .emit_module_separately_WMO:
            return ["-emit-module-separately-wmo"]
        case .no_emit_module_separately_WMO:
            return ["-no-emit-module-separately-wmo"]
        case .emit_module_serialize_diagnostics_path(let arg):
            return ["-emit-module-serialize-diagnostics-path", arg]
        case .emit_module_dependencies_path(let arg):
            return ["-emit-module-dependencies-path", arg]
        case .use_frontend_parseable_output:
            return ["-use-frontend-parseable-output"]
        case .print_explicit_dependency_graph:
            return ["-print-explicit-dependency-graph"]
        case .explicit_dependency_graph_format(let arg):
            return ["-explicit-dependency-graph-format=\(arg)"]
        case .print_preprocessed_explicit_dependency_graph:
            return ["-print-preprocessed-explicit-dependency-graph"]
        case .emit_digester_baseline:
            return ["-emit-digester-baseline"]
        case .emit_digester_baseline_path(let arg):
            return ["-emit-digester-baseline-path", arg]
        case .compare_to_baseline_path(let arg):
            return ["-compare-to-baseline-path", arg]
        case .serialize_breaking_changes_path(let arg):
            return ["-serialize-breaking-changes-path", arg]
        case .digester_breakage_allowlist_path(let arg):
            return ["-digester-breakage-allowlist-path", arg]
        case .digester_mode(let arg):
            return ["-digester-mode", arg]
        case .nostartfiles:
            return ["-nostartfiles"]
        case .gcc_toolchain(let arg):
            return ["-gcc-toolchain", arg]
        case .experimental_clang_importer_direct_cc1_scan:
            return ["-experimental-clang-importer-direct-cc1-scan"]
        case .cache_compile_job:
            return ["-cache-compile-job"]
        case .cache_remarks:
            return ["-Rcache-compile-job"]
        case .cache_disable_replay:
            return ["-cache-disable-replay"]
        case .cas_path(let arg):
            return ["-cas-path", arg]
        case .cas_plugin_path(let arg):
            return ["-cas-plugin-path", arg]
        case .cas_plugin_option(let arg):
            return ["-cas-plugin-option", arg]
        case .clang_scanner_module_cache_path(let arg):
            return ["-clang-scanner-module-cache-path", arg]
        case .scanner_prefix_map(let arg):
            return ["-scanner-prefix-map", arg]
        case .scanner_prefix_map_sdk(let arg):
            return ["-scanner-prefix-map-sdk", arg]
        case .scanner_prefix_map_toolchain(let arg):
            return ["-scanner-prefix-map-toolchain", arg]
        case .cache_replay_prefix_map(let arg):
            return ["-cache-replay-prefix-map", arg]
        case .plugin_path(let arg):
            return ["-plugin-path", arg]
        case .external_plugin_path(let arg):
            return ["-external-plugin-path", arg]
        case .cas_backend:
            return ["-cas-backend"]
        case .cas_backend_mode(let arg):
            return ["-cas-backend-mode=\(arg)"]
        case .cas_emit_casid_file:
            return ["-cas-emit-casid-file"]
        case .load_plugin_library(let arg):
            return ["-load-plugin-library", arg]
        case .load_plugin_executable(let arg):
            return ["-load-plugin-executable", arg]
        case .load_resolved_plugin(let arg):
            return ["-load-resolved-plugin", arg]
        case .in_process_plugin_server_path(let arg):
            return ["-in-process-plugin-server-path", arg]
        case .disable_sandbox:
            return ["-disable-sandbox"]
        }
    }
}
