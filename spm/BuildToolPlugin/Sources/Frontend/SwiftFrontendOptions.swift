public enum SwiftFrontendOptions {
    /// Specify source inputs in a file rather than on the command line
    /// Flags: ArgumentIsFileList, FrontendOption, NoDriverOption
    case filelist(arg: String)
    /// Specify primary inputs in a file rather than on the command line
    /// Flags: ArgumentIsFileList, FrontendOption, NoDriverOption
    case primary_filelist(arg: String)
    /// Specify outputs in a file rather than on the command line
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case output_filelist(arg: String)
    /// Specify supplementary outputs in a file rather than on the command line
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case supplementary_output_file_map(arg: String)
    /// Specify index unit output paths in a file rather than on the command line
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case index_unit_output_path_filelist(arg: String)
    /// Output module documentation file <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_module_doc_path(arg: String)
    /// Output module documentation file for the target variant to <path>
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption, NoDriverOption
    /// Meta var name: <path>
    case emit_variant_module_doc_path(arg: String)
    /// Output basic Make-compatible dependencies file to <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_dependencies_path(arg: String)
    /// Output Swift-style dependencies file to <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_reference_dependencies_path(arg: String)
    /// Output compiler fixits as source edits to <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_fixits_path(arg: String)
    /// Output the ABI descriptor of current module to <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_abi_descriptor_path(arg: String)
    /// Output the ABI descriptor of current target variant module to <path>
    /// Flags: CacheInvariant, FrontendOption, NewDriverOnlyOption, NoDriverOption
    /// Meta var name: <path>
    case emit_variant_abi_descriptor_path(arg: String)
    /// Output semantic info of current module to <path>
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case emit_module_semantic_info_path(arg: String)
    /// Path to diagnostic documentation resources
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case diagnostic_documentation_path(arg: String)
    /// The path to output swift interface files for the compiled source files
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case dump_api_path(arg: String)
    /// The path to collect the group information of the compiled module
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case group_info_path(arg: String)
    /// Directory of prebuilt modules for loading module interfaces
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case prebuilt_module_cache_path(arg: String)
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Alias of: prebuilt_module_cache_path
    case prebuilt_module_cache_path_EQ(arg: String)
    /// Directory of module interfaces as backups to those from SDKs
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case backup_module_interface_path(arg: String)
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    /// Alias of: backup_module_interface_path
    case backup_module_interface_path_EQ(arg: String)
    /// Emit textual output in a parseable format
    /// Flags: CacheInvariant, FrontendOption, NoDriverOption
    case frontend_parseable_output
    /// Produce output for this file, not the whole module
    /// Flags: ArgumentIsPath, FrontendOption, NoDriverOption
    case primary_file(arg: String)
    /// The path to a blocklist configuration file
    /// Flags: ArgumentIsPath, FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case block_list_file(arg: String)
    /// Flags: FrontendOption, NoDriverOption
    /// Alias of: target
    case triple(arg: String)
    /// Emit a module documentation file based on documentation comments
    /// Flags: FrontendOption, NoDriverOption
    case emit_module_doc
    /// Output module source info file
    /// Flags: FrontendOption, NoDriverOption
    case emit_module_source_info
    /// Avoid getting source location from .swiftsourceinfo files
    /// Flags: FrontendOption, NoDriverOption
    case ignore_module_source_info
    /// Merge the input modules without otherwise processing them
    /// Flags: FrontendOption, NoDriverOption
    /// Other options: ModeOpt
    case merge_modules
    /// Emit a Swift-style dependencies file
    /// Flags: FrontendOption, NoDriverOption
    case emit_reference_dependencies
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case serialize_module_interface_dependency_hashes
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: serialize_module_interface_dependency_hashes
    case serialize_parseable_module_interface_dependency_hashes
    /// The install_name to use in an emitted TBD file
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case tbd_install_name(arg: String)
    /// Flags: FrontendOption, NoDriverOption
    /// Alias of: tbd_install_name
    case tbd_install_name_EQ(arg: String)
    /// The current_version to use in an emitted TBD file
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <version>
    case tbd_current_version(arg: String)
    /// Flags: FrontendOption, NoDriverOption
    /// Alias of: tbd_current_version
    case tbd_current_version_EQ(arg: String)
    /// The compatibility_version to use in an emitted TBD file
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <version>
    case tbd_compatibility_version(arg: String)
    /// Flags: FrontendOption, NoDriverOption
    /// Alias of: tbd_compatibility_version
    case tbd_compatibility_version_EQ(arg: String)
    /// If the TBD file should indicate it's being generated during InstallAPI
    /// Flags: FrontendOption, NoDriverOption
    case tbd_is_installapi
    /// Verify diagnostics against expected-{error|warning|note} annotations
    /// Flags: FrontendOption, NoDriverOption
    case verify
    /// Verify diagnostics in this file in addition to source files
    /// Flags: FrontendOption, NoDriverOption
    case verify_additional_file(arg: String)
    /// Check for diagnostics with the prefix expected-<PREFIX> as well as expected-
    /// Flags: FrontendOption, NoDriverOption
    case verify_additional_prefix(arg: String)
    /// Like -verify, but updates the original source file
    /// Flags: FrontendOption, NoDriverOption
    case verify_apply_fixes
    /// Allow diagnostics for '<unknown>' location in verify mode
    /// Flags: FrontendOption, NoDriverOption
    case verify_ignore_unknown
    /// Verify the generic signatures in the given module
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <module-name>
    case verify_generic_signatures(arg: String)
    /// Keep emitting subsequent diagnostics after a fatal error
    /// Flags: FrontendOption, NoDriverOption
    case show_diagnostics_after_fatal
    /// Automatically import declared cross-import overlays.
    /// Flags: FrontendOption, NoDriverOption
    case enable_cross_import_overlays
    /// Do not automatically import declared cross-import overlays.
    /// Flags: FrontendOption, NoDriverOption
    case disable_cross_import_overlays
    /// Enable checking of @testable
    /// Flags: FrontendOption, NoDriverOption
    case enable_testable_attr_requires_testable_module
    /// Disable checking of @testable
    /// Flags: FrontendOption, NoDriverOption
    case disable_testable_attr_requires_testable_module
    /// Don't import Clang SPIs as Swift SPIs
    /// Flags: FrontendOption, NoDriverOption
    case disable_clang_spi
    /// Enable checking the target OS of serialized modules
    /// Flags: FrontendOption, NoDriverOption
    case enable_target_os_checking
    /// Disable checking the target OS of serialized modules
    /// Flags: FrontendOption, NoDriverOption
    case disable_target_os_checking
    /// Compare legacy DeclContext- to ASTScope-based unqualified name lookup (for debugging)
    /// Flags: FrontendOption, NoDriverOption
    case crosscheck_unqualified_lookup
    /// Use stored Clang function types for computing canonical types.
    /// Flags: FrontendOption, NoDriverOption
    case use_clang_function_types
    /// Print Clang importer statistics
    /// Flags: FrontendOption, NoDriverOption
    case print_clang_stats
    /// Always serialize options for debugging (default: only for apps)
    /// Flags: FrontendOption, NoDriverOption
    case serialize_debugging_options
    /// Remap source paths in debug info
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <prefix=replacement>
    case serialized_path_obfuscate(arg: String)
    /// Avoid printing actual module content into ABI descriptor file
    /// Flags: FrontendOption, NoDriverOption
    case empty_abi_descriptor
    /// Never serialize options for debugging (default: only for apps)
    /// Flags: FrontendOption, NoDriverOption
    case no_serialize_debugging_options
    /// Add dependent library
    /// Flags: FrontendOption, NoDriverOption
    case autolink_library(arg: String)
    /// Disable typo correction
    /// Flags: FrontendOption, NoDriverOption
    case disable_typo_correction
    /// Disable building Swift modules implicitly by the compiler
    /// Flags: FrontendOption, NoDriverOption
    case disable_implicit_swift_modules
    /// Specify Swift module input explicitly built from textual interface
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <name>=<path>
    case swift_module_file(arg: String)
    /// Specify the cross import module
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <moduleName> <crossImport.swiftoverlay>
    case swift_module_cross_import(args: [String])
    /// Specify canImport module name
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <moduleName>
    case module_can_import(arg: String)
    /// Specify canImport module and versions
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <moduleName> <version> <underlyingVersion>
    case module_can_import_version(args: [String])
    /// Disable searching for cross import overlay file
    /// Flags: FrontendOption, NoDriverOption
    case disable_cross_import_overlay_search
    /// Specify a JSON file containing information of explicit Swift modules
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case explicit_swift_module_map(arg: String)
    /// Specify a list of protocols for extraction of conformances' const values'
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case const_gather_protocols_file(arg: String)
    /// Specify a JSON file containing information of external Swift module dependencies
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: <path>
    case placeholder_dependency_module_map(arg: String)
    /// When performing a dependency scan, only identify all imports of the main Swift module sources
    /// Flags: FrontendOption, NoDriverOption
    case import_prescan
    /// After performing a dependency scan, serialize the scanner's internal state.
    /// Flags: FrontendOption, NoDriverOption
    case serialize_dependency_scan_cache
    /// For performing a dependency scan, deserialize the scanner's internal state from a prior scan.
    /// Flags: FrontendOption, NoDriverOption
    case reuse_dependency_scan_cache
    /// For performing a dependency scan with a prior scanner state, validate module dependencies.
    /// Flags: FrontendOption, NoDriverOption
    case validate_prior_dependency_scan_cache
    /// The path to output the dependency scanner's internal state.
    /// Flags: FrontendOption, NoDriverOption
    case dependency_scan_cache_path(arg: String)
    /// Emit remarks indicating use of the serialized module dependency scanning cache.
    /// Flags: FrontendOption, NoDriverOption
    case dependency_scan_cache_remarks
    /// Perform dependency scanning in-parallel.
    /// Flags: FrontendOption, NoDriverOption
    case parallel_scan
    /// Perform dependency scanning in a single-threaded fashion.
    /// Flags: FrontendOption, NoDriverOption
    case no_parallel_scan
    /// Run SIL copy propagation with lexical lifetimes to shorten object lifetimes while preserving variable lifetimes.
    /// Flags: FrontendOption, NoDriverOption
    case enable_copy_propagation
    /// Whether to enable copy propagation
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: true|requested-passes-only|false
    case copy_propagation_state_EQ(arg: String)
    /// Disable inference of Sendable conformances for public structs and enums
    /// Flags: FrontendOption, NoDriverOption
    case disable_infer_public_concurrent_value
    /// Control access note remarks (default: all)
    /// Flags: FrontendOption, NoDriverOption
    /// Meta var name: none|failures|all|all-validate
    case Raccess_note(arg: String)
    /// Flags: FrontendOption, NoDriverOption
    /// Alias of: Raccess_note
    case Raccess_note_EQ(arg: String)
    /// Whether to enable lexical lifetimes
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    /// Meta var name: true|false
    case enable_lexical_lifetimes(arg: String)
    /// Enable lexical lifetimes
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    case enable_lexical_lifetimes_noArg
    /// Whether to enable destroy hoisting
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    /// Meta var name: true|false
    case enable_destroy_hoisting(arg: String)
    /// Enable Objective-C interop code generation and config directives
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_objc_interop
    /// Disable Objective-C interop code generation and config directives
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case disable_objc_interop
    /// Type-erases opaque types that conform to @_typeEraser protocols
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_opaque_type_erasure
    /// Enable requiring uses of @objc to require importing the Foundation module
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_objc_attr_requires_foundation_module
    /// Disable requiring uses of @objc to require importing the Foundation module
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case disable_objc_attr_requires_foundation_module
    /// Enable experimental concurrency model
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_concurrency
    /// Enable experimental move only
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_move_only
    /// Enable experimental 'distributed' actors and functions
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_distributed
    /// Enable flow-sensitive concurrent captures
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_flow_sensitive_concurrent_captures
    /// Disable experimental diagnostics when importing C, C++, and Objective-C libraries
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case disable_experimental_clang_importer_diagnostics
    /// Enable experimental eager diagnostics reporting on the importability of all referenced C, C++, and Objective-C libraries
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_eager_clang_module_diagnostics
    /// Enable experimental pairwise 'buildBlock' for result builders
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_pairwise_build_block
    /// Deprecated, use -enable-library-evolution instead
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_resilience
    /// Enable experimental concurrency in top-level code
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case enable_experimental_async_top_level
    /// Add public dependent library
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOption, NoDriverOption
    case public_autolink_library(arg: String)
    /// Use the experimental Swift based closure-specialization optimization pass instead of the existing C++ one
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_swift_based_closure_specialization
    /// Control whether checked continuations are used when bridging async calls from Swift to ObjC: 'on', 'off'
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case checked_async_objc_bridging(arg: String)
    /// Debug the constraint-based type checker
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_constraints
    /// Debug the constraint solver at a given attempt
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_constraints_attempt(arg: String)
    /// Debug the constraint solver for expressions on <line>
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <line>
    case debug_constraints_on_line(arg: String)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: debug_constraints_on_line
    case debug_constraints_on_line_EQ(arg: String)
    /// Disable per-name lazy member loading (obsolete)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_named_lazy_member_loading
    /// Import all of a type's import-as-member globals together, as Swift 5.10 and earlier did; temporary workaround for modules that are sensitive to this change
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_named_lazy_import_as_member_loading
    /// Enables dumping rewrite systems from the generics implementation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_requirement_machine
    /// Fine-grained debug output from the generics implementation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_requirement_machine(arg: String)
    /// Dumps the results of each macro expansion
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_macro_expansions
    /// Specify when to emit macro expansion file: 'none', 'debug', or 'diagnostics'
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case emit_macro_expansion_files(arg: String)
    /// Print out request evaluator cache statistics at the end of the compilation job
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case analyze_request_evaluator
    /// Print out requirement machine statistics at the end of the compilation job
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case analyze_requirement_machine
    /// Set the maximum number of rules before giving up
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case requirement_machine_max_rule_count(arg: String)
    /// Set the maximum rule length before giving up
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case requirement_machine_max_rule_length(arg: String)
    /// Set the maximum concrete type nesting depth before giving up
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case requirement_machine_max_concrete_nesting(arg: String)
    /// Set the maximum concrete number of attempts at splitting concrete equivalence classes before giving up. There should never be a reason to change this
    /// Flags: DoesNotAffectIncrementalBuild, FrontendOption, HelpHidden, NoDriverOption
    case requirement_machine_max_split_concrete_equiv_class_attempts(arg: String)
    /// Disable preprocessing pass to eliminate conformance requirements on generic parameters which are made concrete
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_requirement_machine_concrete_contraction
    /// Disable stronger minimization algorithm, for debugging only
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_requirement_machine_loop_normalization
    /// Disable re-use of requirement machines for minimization, for debugging only
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_requirement_machine_reuse
    /// Enable more correct opaque archetype support, which is off by default because it might fail to produce a convergent rewrite system
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_requirement_machine_opaque_archetypes
    /// Enables dumping type witness systems from associated type inference
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_type_witness_systems
    /// Enables verification of debug info mangling
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_round_trip_debug_types
    /// Disables verification of debug info mangling
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_round_trip_debug_types
    /// Debug generic signatures
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_generic_signatures
    /// Print real requirements in -debug-generic-signatures output
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_inverse_requirements
    /// Triggers llvm fatal_error if typechecker tries to typecheck a decl with the provided prefix name
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_forbid_typecheck_prefix(arg: String)
    /// Type-check lazily as needed to produce requested outputs
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_lazy_typecheck
    /// Write an invalid declaration into swiftinterface files
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_emit_invalid_swiftinterface_syntax
    /// Print out debug dumps when cycles are detected in evaluation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_cycles
    /// Dumps the time it takes to type-check each function body
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_time_function_bodies
    /// Dumps the time it takes to type-check each expression
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_time_expression_type_checking
    /// Force an assertion failure immediately
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: DebugCrashOpt
    case debug_assert_immediately
    /// Force an assertion failure after parsing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: DebugCrashOpt
    case debug_assert_after_parse
    /// Force a crash immediately
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: DebugCrashOpt
    case debug_crash_immediately
    /// Force a crash after parsing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: DebugCrashOpt
    case debug_crash_after_parse
    /// After performing a dependency scan, serialize and then deserialize the scanner's internal state.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_test_dependency_scan_cache_serialization
    /// Process swift code as if running in the debugger
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debugger_support
    /// Disable ClangImporter and forward all requests straight the DWARF importer.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_clangimporter_source_import
    /// Disable the implicit import of the _Concurrency module.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_implicit_concurrency_module_import
    /// Disable the implicit import of the _StringProcessing module.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_implicit_string_processing_module_import
    /// Disable the implicit import of the C++ Standard Library module.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_implicit_cxx_module_import
    /// Don't run SIL ARC optimization passes.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_arc_opts
    /// Don't run SIL OSSA optimization passes.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_ossa_opts
    /// Disable use of partial_apply in SIL generation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_sil_partial_apply
    /// Enable speculative devirtualization pass.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_spec_devirt
    /// Enables an optimization pass to demote async functions.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_async_demotion
    /// Enables optimization assumption that functions rarely throw errors.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_throws_prediction
    /// Disables optimization assumption that functions rarely throw errors.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_throws_prediction
    /// Enables optimization assumption that calls to no-return functions are cold.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_noreturn_prediction
    /// Disables optimization assumption that calls to no-return functions are cold.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_noreturn_prediction
    /// Don't respect access control restrictions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_access_control
    /// Respect access control restrictions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_access_control
    /// Include initializers when completing a postfix expression
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case code_complete_inits_in_postfix_expr
    /// Use heuristics to guess whether we want call pattern completions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case code_complete_call_pattern_heuristics
    /// Disable autolinking against the provided framework
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_autolink_framework(arg: String)
    /// Disable autolinking against the provided library
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_autolink_library(arg: String)
    /// Disable autolinking against all frameworks
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_autolink_frameworks
    /// Disable all Swift autolink directives
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_all_autolinking
    /// Disable generation of all Swift _FORCE_LOAD symbols
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_force_load_symbols
    /// Don't run diagnostic passes
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_diagnostic_passes
    /// Don't run LLVM optimization passes
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_llvm_optzns
    /// Don't run SIL performance optimization passes
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_sil_perf_optzns
    /// Don't run Swift specific LLVM optimization passes.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_swift_specific_llvm_optzns
    /// Don't run the LLVM IR verifier.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_llvm_verify
    /// Don't add names to local values in LLVM IR
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_llvm_value_names
    /// Dump JIT contents
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_jit(arg: String)
    /// Add names to local values in LLVM IR
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_llvm_value_names
    /// Enable emission of mangled names in anonymous context descriptors
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_anonymous_context_mangled_names
    /// Disable emission of reflection metadata for nominal types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_reflection_metadata
    /// Emit reflection metadata for debugger only, don't make them available at runtime
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case reflection_metadata_for_debugger_only
    /// Disable emission of names of stored properties and enum cases inreflection metadata
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_reflection_names
    /// Emit functions to separate sections.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case function_sections
    /// Emit LLVM IR into a single LLVM module in multithreaded mode.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case enable_single_module_llvm_emission
    /// Produce a valid but dummy object file when building a library module
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case emit_empty_object_file
    /// Emit runtime checks for correct stack promotion of objects.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case stack_promotion_checks
    /// Limit the size of stack promoted objects to the provided number of bytes.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case stack_promotion_limit(arg: String)
    /// Dump Clang diagnostics to stderr
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_clang_diagnostics
    /// Dump the importer's Swift-name-to-Clang-name lookup tables to stderr
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case dump_clang_lookup_tables
    /// Disable validating system headers in the Clang importer
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_modules_validate_system_headers
    /// Emit locations during SIL emission
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case emit_verbose_sil
    /// Emit PCH for imported Objective-C header file
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: ModeOpt
    case emit_pch
    /// Disable validating the persistent PCH
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case pch_disable_validation
    /// Do not verify ownership invariants during SIL Verification
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_sil_ownership_verifier
    /// Suppress static violations of exclusive access with swap()
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case suppress_static_exclusivity_swap
    /// Enable experimental #assert
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_static_assert
    /// Disable substituted function types for SIL type lowering of function values
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_subst_sil_function_types
    /// Enable experimental support for named opaque result types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_named_opaque_types
    /// Enable experimental support for explicit existential types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_explicit_existential_types
    /// Enable experimental support for implicitly opened existentials
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_opened_existential_types
    /// Disable experimental support for implicitly opened existentials
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_experimental_opened_existential_types
    /// Attempt to recover from missing xrefs (etc) in swiftmodules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_deserialization_recovery
    /// Don't attempt to recover from missing xrefs (etc) in swiftmodules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_deserialization_recovery
    /// Avoid reading potentially unsafe decls in swiftmodules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_deserialization_safety
    /// Don't avoid reading potentially unsafe decls in swiftmodules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_deserialization_safety
    /// Attempt unsafe recovery for imported modules with broken modularization
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case force_workaround_broken_modules
    /// Enable experimental string processing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_string_processing
    /// Disable experimental string processing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_experimental_string_processing
    /// Enable experimental lifetime dependence inference
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_experimental_lifetime_dependence_inference
    /// Disable experimental lifetime dependence inference
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_experimental_lifetime_dependence_inference
    /// Disable checking for potentially unavailable APIs
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_availability_checking
    /// Deprecated, will be removed in future versions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case warn_on_potentially_unavailable_enum_case
    /// Downgrade the editor placeholder error to a warning
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case warn_on_editor_placeholder
    /// Deprecated, will be removed in future versions.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case report_errors_to_debugger
    /// Deprecated, has no effect
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_swift3_objc_inference
    /// Deprecated, has no effect
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_swift3_objc_inference
    /// Add 'dynamic' to all declarations
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case enable_implicit_dynamic
    /// Ignore all checks for module resilience.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case bypass_resilience
    /// Use LLVM IR Virtual Function Elimination on Swift class virtual tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case enable_llvm_vfe
    /// Use LLVM IR Witness Method Elimination on Swift protocol witness tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case enable_llvm_wme
    /// Allow internalizing public symbols and vtables at link time (assume all client code of public types is part of the same link unit, or that external symbols are explicitly requested via -exported_symbols_list)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case internalize_at_link
    /// Allow removal of runtime metadata records (public types, protocol conformances) based on whether they're used or unused
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case conditional_runtime_records
    /// Emit symbol definitions as mergeable (linkonce_odr)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case mergeable_symbols
    /// Avoid preallocating metadata instantiation caches in globals
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case disable_preallocated_instantiation_caches
    /// Avoid allocating static objects in a read-only data section
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case disable_readonly_static_objects
    /// Lower traps to calls to this function instead of trap instructions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <name>
    case trap_function(arg: String)
    /// Disable calling the previous implementation in dynamic replacements
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case disable_previous_implementation_calls_in_dynamic_replacements
    /// Enable chaining of dynamic replacements
    /// Flags: FrontendOption, HelpHidden, NoDriverOption, NoInteractiveOption
    case enable_dynamic_replacement_chaining
    /// Diagnose classes with unstable mangled names adopting NSCoding
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_nskeyedarchiver_diagnostics
    /// Allow classes with unstable mangled names to adopt NSCoding
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_nskeyedarchiver_diagnostics
    /// Diagnose switches over non-frozen enums without catch-all cases
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_nonfrozen_enum_exhaustivity_diagnostics
    /// Allow switches over non-frozen enums without catch-all cases
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_nonfrozen_enum_exhaustivity_diagnostics
    /// Warns when type-checking a function takes longer than <n> ms
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <n>
    case warn_long_function_bodies(arg: String)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: warn_long_function_bodies
    case warn_long_function_bodies_EQ(arg: String)
    /// Warns when type-checking an expression takes longer than <n> ms
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <n>
    case warn_long_expression_type_checking(arg: String)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: warn_long_expression_type_checking
    case warn_long_expression_type_checking_EQ(arg: String)
    /// Emits a remark if an imported module needs to be re-compiled from its module interface
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case Rmodule_interface_rebuild
    /// Downgrade error to warning when typechecking emitted module interfaces
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case downgrade_typecheck_interface_error
    /// Load Swift modules in memory
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_volatile_modules
    /// Expression type checking timeout, in seconds
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case solver_expression_time_threshold_EQ(arg: String)
    /// Expression type checking scope limit
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case solver_scope_threshold_EQ(arg: String)
    /// Expression type checking trail change limit
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case solver_trail_threshold_EQ(arg: String)
    /// Disable the shrink phase of expression type checking
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case solver_disable_shrink
    /// Disable the component splitter phase of expression type checking
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case solver_disable_splitter
    /// Disable all the hacks in the constraint solver
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_constraint_solver_performance_hacks
    /// Enable operator designated types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_operator_designated_types
    /// Diagnose invalid ephemeral to non-ephemeral conversions as errors
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_invalid_ephemeralness_as_error
    /// Diagnose invalid ephemeral to non-ephemeral conversions as warnings
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_invalid_ephemeralness_as_error
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case switch_checking_invocation_threshold_EQ(arg: String)
    /// Enable the new operator decl and precedencegroup lookup behavior
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_new_operator_lookup
    /// Disable the new operator decl and precedencegroup lookup behavior
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_new_operator_lookup
    /// Enable importing of Swift source files
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_source_import
    /// Allow throwing function calls without 'try'
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_throw_without_try
    /// Turn all throw sites into immediate traps
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case throws_as_traps
    /// Implicitly import the specified module
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case import_module(arg: String)
    /// Implicitly import the specified module with @testable
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case testable_import_module(arg: String)
    /// Print various statistics
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case print_stats
    /// Print errors if the compile OnoneSupport module is missing symbols
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case check_onone_completeness
    /// Instrument the code with calls to an intrinsic that record the expected values of local variables so they can be compared against the results from the debugger.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debugger_testing_transform
    /// Disable debugger shadow copies of local variables.This option is only useful for testing the compiler.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_debugger_shadow_copies
    /// Disable concrete type metadata access by mangled name
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_concrete_type_metadata_mangled_name_accessors
    /// Disable referencing stdlib symbols via mangled names in reflection mangling
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_standard_substitutions_in_reflection_mangling
    /// Apply the playground semantics and transformation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case playground
    /// Provide an option to the playground transform (if enabled)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case playground_option(arg: String)
    /// Omit instrumentation that has a high runtime performance impact
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case playground_high_performance
    /// Disable playground transformation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_playground_transform
    /// Apply the 'program counter simulation' macro
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case pc_macro
    /// Don't emit DWARF skeleton CUs for imported Clang modules. Use this when building a redistributable static archive.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case no_clang_module_breadcrumbs
    /// Register Objective-C classes as if the JIT were in use
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case use_jit
    /// Controls the aggressiveness of performance inlining
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <50>
    case sil_inline_threshold(arg: String)
    /// Controls the aggressiveness of performance inlining in -Osize mode by reducing the base benefits of a caller (lower value permits more inlining!)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <2>
    case sil_inline_caller_benefit_reduction_factor(arg: String)
    /// Controls the aggressiveness of loop unrolling
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <250>
    case sil_unroll_threshold(arg: String)
    /// Verify SIL after each transform
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case sil_verify_all
    /// Completely disable SIL verification
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case sil_verify_none
    /// Verify ownership after each transform
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case sil_ownership_verify_all
    /// Verify all SubstitutionMaps on construction
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case verify_all_substitution_maps
    /// Do not eliminate functions in Mandatory Inlining/SILCombine dead functions. (for debugging only)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case sil_debug_serialization
    /// Stop optimizing at SIL time before we lower ownership from SIL. Intended only for SIL ossa tests
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case sil_stop_optzns_before_lowering_ownership
    /// Before IRGen, count all the various SIL instructions. Must be used in conjunction with -print-stats.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case print_inst_counts
    /// Write the SIL into a file and generate debug-info to debug on SIL  level.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case debug_on_sil
    /// Deprecated, use '-sil-based-debuginfo' instead
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case legacy_gsil
    /// Print the LLVM inline tree.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case print_llvm_inline_tree
    /// Disable incremental llvm code generation.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_incremental_llvm_codegeneration
    /// Ignore @inline(__always) attributes.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case ignore_always_inline
    /// When printing SIL, print out all sil entities sorted by name to ease diffing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case emit_sorted_sil
    /// Import getters and setters as computed properties in Swift
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case cxx_interop_getters_setters_as_properties
    /// Do not require C++ interoperability to be enabled when importing a Swift module that enables C++ interoperability
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case cxx_interop_disable_requirement_at_import
    /// Testing flag that will be eliminated soon. Do not use.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case cxx_interop_use_opaque_pointer_for_moveonly
    /// Allocate internal data structures using malloc (for memory debugging)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case use_malloc
    /// Immediate mode
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: ModeOpt
    case interpret
    /// Verify compile-time and runtime type layout information for type
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <type>
    case verify_type_layout(arg: String)
    /// Use the pass pipeline defined by <pass_pipeline_file>
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <pass_pipeline_file>
    case external_pass_pipeline_filename(arg: String)
    /// Emit index data for imported serialized swift system modules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case index_system_modules
    /// Avoid emitting index data for the standard library.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case index_ignore_stdlib
    /// Parse input file(s) and dump interface token hash(es)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: ModeOpt
    case dump_interface_hash
    /// Treat the (single) input as a swiftinterface and produce a module
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: ModeOpt
    case compile_module_from_interface
    /// Use the specified command-line to build the module from interface, instead of flags specified in the interface
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case explicit_interface_module_build
    /// Use the specified -Xcc options to build a PCM by using Clang frontend directly, bypassing the Clang driver
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case direct_clang_cc1_module_build
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: compile_module_from_interface
    /// Other options: ModeOpt
    case build_module_from_parseable_interface
    /// Treat the (single) input as a swiftinterface and typecheck it
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Other options: ModeOpt
    case typecheck_module_from_interface
    /// When emitting a module interface, preserve types as they were written in the source
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case module_interface_preserve_types_as_written
    /// When emitting a module interface, disambiguate modules using distinct alias names
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case alias_module_names_in_module_interface
    /// When emitting a module interface, disable disambiguating modules using distinct alias names
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_alias_module_names_in_module_interface
    /// Enable experimental support for SPI imports
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_spi_imports
    /// Disable adding to the module interface imports used from API and missing from the sources
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_print_missing_imports_in_module_interface
    /// When emitting a module interface or SIL, emit additional @convention arguments, regardless of whether they were written in the source. Also requires -use-clang-function-types to be enabled.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_print_full_convention
    /// Force public linkage for private symbols. Used by LLDB.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case force_public_linkage
    /// Diagnostics will be used in editor
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case diagnostics_editor_mode
    /// Compare the symbols in the IR against the TBD file that would be generated.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <level>
    case validate_tbd_against_ir_EQ(arg: String)
    /// Bypass checks for batch-mode errors.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case bypass_batch_mode_checks
    /// Enable verification of access markers used to enforce exclusivity.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_verify_exclusivity
    /// Disable verification of access markers used to enforce exclusivity.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_verify_exclusivity
    /// Completely disable legacy type layout
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_legacy_type_info
    /// Do not statically specialize metadata for generic types at types that are known to be used in source.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_generic_metadata_prespecialization
    /// Statically specialize metadata for generic types at types that are known to be used in source.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case prespecialize_generic_metadata
    /// Read legacy type layout from the given path instead of default path
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case read_legacy_type_info_path_EQ(arg: String)
    /// One of 'all', 'resilient' or 'fragile'
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case type_info_dump_filter_EQ(arg: String)
    /// One of 'auto', 'always' or 'never'
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case swift_async_frame_pointer_EQ(arg: String)
    /// Path to a Json file indicating module name to installname map for @_originallyDefinedIn
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <path>
    case previous_module_installname_map_file(arg: String)
    /// Enable type layout based lowering
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_type_layouts
    /// Disable type layout based lowering
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_type_layouts
    /// Force type layout based lowering for structs
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case force_struct_type_layouts
    /// Enable layout string based value witnesses
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_layout_string_value_witnesses
    /// Enable large loadable types register to memory pass
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_large_loadable_types_reg2mem
    /// Disable large loadable types register to memory pass
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_large_loadable_types_reg2mem
    /// Whether to skip heapifying stack metadata packs when possible.
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    /// Meta var name: true|false
    case enable_pack_metadata_stack_promotion(arg: String)
    /// Skip heapifying stack metadata packs when possible.
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    case enable_pack_metadata_stack_promotion_noArg
    /// Disable layout string based value witnesses
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_layout_string_value_witnesses
    /// Enable runtime instantiation of layout string value witnesses for generic types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_layout_string_value_witnesses_instantiation
    /// Disable runtime instantiation of layout string value witnesses for generic types
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_layout_string_value_witnesses_instantiation
    /// Don't lock interface file when building module
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_interface_lockfile
    /// Directory for bridging header to be printed in compatibility header
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <path>
    case bridging_header_directory_for_print(arg: String)
    /// Name of the entry point function
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <string>
    case entry_point_function_name(arg: String)
    /// The version of target SDK used for compilation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case target_sdk_version(arg: String)
    /// The version of target variant SDK used for compilation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case target_variant_sdk_version(arg: String)
    /// Canonical name of the target SDK used for compilation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case target_sdk_name(arg: String)
    /// Specify Swift module may be ready to use for an interface
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <path>
    case candidate_module_file(arg: String)
    /// Use resources in the static resource directory
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case use_static_resource_dir
    /// Disallow building binary module from textual interface
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_building_interface
    /// Skip type-checking function bodies and all SIL generation
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_skip_all_function_bodies
    /// Attempt to output .swiftmodule, regardless of compilation errors
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_allow_module_with_compiler_errors
    /// Skip decls that are not exported to clients
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_skip_non_exportable_decls
    /// Number of retrying opening a file if previous open returns a bad file descriptor error.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case bad_file_descriptor_retry_count(arg: String)
    /// Run the AST verifier during compilation. NOTE: This lets the user override the default behavior on whether or not the ASTVerifier is run. The default behavior is to run the verifier when asserts are enabled and not run it when asserts are disabled. NOTE: Can not be used if disable-ast-verifier is used as well
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_ast_verifier
    /// Do not run the AST verifier during compilation. NOTE: This lets the user override the default behavior on whether or not the ASTVerifier is run. The default behavior is to run the verifier when asserts are enabled and not run it when asserts are disabled. NOTE: Can not be used if enable-ast-verifier is used as well
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_ast_verifier
    /// Always serialize SIL in ossa form. If this flag is not passed in, when optimizing ownership will be lowered before serializing SIL
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    case enable_ossa_modules
    /// Allow recompilation of a non-OSSA module to an OSSA module when imported from another OSSA module
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_recompilation_to_ossa_module
    /// Enable SIL Opaque Values
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_sil_opaque_values
    /// Disable SIL Opaque Values
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_sil_opaque_values
    /// Path of the new driver to be used
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <path>
    case new_driver_path(arg: String)
    /// Skip the emission of fine grained module tracing file.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_fine_module_tracing
    /// Which declarations should be exposed in the generated clang header.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: all-public|has-expose-attr
    case clang_header_expose_decls(arg: String)
    /// Allow the compiler to assume that APIs from the specified module are exposed to C/C++/Objective-C in another generated header, so that APIs in the current module that depend on declarations from the specified module can be exposed in the generated header.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <imported-module-name>=<generated-header-name>
    case clang_header_expose_module(arg: String)
    /// Weakly link symbols for declarations that were introduced at the deployment target. Symbols introduced before the deployment target are still strongly linked.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case weak_link_at_target
    /// Which concurrency model is used.  Defaults to standard.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: standard|task-to-thread
    case concurrency_model(arg: String)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: concurrency_model
    case concurrency_model_EQ(arg: String)
    /// Enable the stack protector
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_stack_protector
    /// Disable the stack-protector
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_stack_protector
    /// Enable the stack protector by moving values to temporaries
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_move_inout_stack_protector
    /// Enable import of custom ptrauth qualified field function pointers. This is on by default.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_import_ptrauth_field_function_pointers
    /// Disable import of custom ptrauth qualified field function pointers
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_import_ptrauth_field_function_pointers
    /// Enable lifetime dependence diagnostics for Nonescapable types.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_lifetime_dependence_diagnostics
    /// Disable lifetime dependence diagnostics for Nonescapable types.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_lifetime_dependence_diagnostics
    /// Enable a more aggressive reg2mem heuristic
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_aggressive_reg2mem
    /// Disable a more aggressive reg2mem heuristic
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_aggressive_reg2mem
    /// Enable collocate metadata functions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_collocate_metadata_functions
    /// Disable collocate metadata functions
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_collocate_metadata_functions
    /// Enable colocate type descriptors
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_colocate_type_descriptors
    /// Disable colocate type descriptors
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_colocate_type_descriptors
    /// Enable relative protocol witness tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_relative_protocol_witness_tables
    /// Disable relative protocol witness tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_relative_protocol_witness_tables
    /// Enable relative protocol witness tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_fragile_resilient_protocol_witnesses
    /// Disable relative protocol witness tables
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_fragile_resilient_protocol_witnesses
    /// Enable async frame push pop metadata
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_async_frame_push_pop_metadata
    /// Disable async frame push pop metadata
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_async_frame_push_pop_metadata
    /// Always emit async frame stack frames (frame-pointer=all)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_async_frame_pointer_all
    /// Disable always emit async frame stack frames
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_async_frame_pointer_all
    /// Enable splitting of cold code when optimizing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_split_cold_code
    /// Disable splitting of cold code when optimizing
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_split_cold_code
    /// Enable the new llvm pass manager
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_new_llvm_pass_manager
    /// Disable the new llvm pass manager
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_new_llvm_pass_manager
    /// Enable profiling marker thunks
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_profiling_marker_thunks
    /// Disable profiling marker thunks
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_profiling_marker_thunks
    /// Enable objective-c protocol symbolic references
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_objective_c_protocol_symbolic_references
    /// Disable objective-c protocol symbolic references
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_objective_c_protocol_symbolic_references
    /// Disable emission of a section with references to class_ro_t of generic class patterns
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_emit_generic_class_ro_t_list
    /// Enable emission of a section with references to class_ro_t of generic class patterns
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_emit_generic_class_ro_t_list
    /// Check compiler output determinism by running it twice
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_deterministic_check
    /// Always compile output files even it might not change the results
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case always_compile_output_files
    /// Cache Key for input file
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case input_file_key(arg: String)
    /// Cache Key for bridging header pch
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case bridging_header_pch_key(arg: String)
    /// Do not use clang include tree, fallback to use CAS filesystem to build clang modules
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case no_clang_include_tree
    /// Root CASID for CAS FileSystem
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <cas-id>
    case cas_fs(arg: String)
    /// Clang Include Tree CASID
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <cas-id>
    case clang_include_tree_root(arg: String)
    /// Clang Include Tree FileList CASID
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <cas-id>
    case clang_include_tree_filelist(arg: String)
    /// Enable use of @_spiOnly imports
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case experimental_spi_only_imports
    /// Require linear OSSA lifetimes after SILGen
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_ossa_complete_lifetimes
    /// Do not require linear OSSA lifetimes after SILGen
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_ossa_complete_lifetimes
    /// Verify linear OSSA lifetimes after SILGen
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case enable_ossa_verify_complete
    /// Do not verify linear OSSA lifetimes after SILGen
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_ossa_verify_complete
    /// Which calling convention is used to perform non-swift calls. Defaults to llvm's standard C calling convention.
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case platform_c_calling_convention(arg: String)
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Alias of: platform_c_calling_convention
    case platform_c_calling_convention_EQ(arg: String)
    /// Disable sending args and results when region based isolation is enabled. Only enabled with asserts
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case disable_sending_args_and_results_with_region_isolation
    /// Validate binary modules in the dependency scanner
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case scanner_module_validation
    /// Do not validate binary modules in scanner and delegate the validation to swift-frontend
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case no_scanner_module_validation
    /// Module loading mode
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: only-interface|prefer-interface|prefer-serialized|only-serialized
    case module_load_mode(arg: String)
    /// Directory for generated files from swift dependency scanner
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case scanner_output_dir(arg: String)
    /// Write generated output from scanner for debugging purpose
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    case scanner_debug_write_output
    /// Path of the platform inheritance platform map
    /// Flags: FrontendOption, HelpHidden, NoDriverOption
    /// Meta var name: <path>
    case platform_availability_inheritance_map_path(arg: String)
    /// Disable round trip through the new swift parser
    /// Flags: FrontendOption, HelpHidden, ModuleInterfaceOptionIgnorable, NoDriverOption
    case disable_experimental_parser_round_trip

    private var flags: [String] {
        switch self {
        case .filelist(let arg):
            return ["-filelist", arg]
        case .primary_filelist(let arg):
            return ["-primary-filelist", arg]
        case .output_filelist(let arg):
            return ["-output-filelist", arg]
        case .supplementary_output_file_map(let arg):
            return ["-supplementary-output-file-map", arg]
        case .index_unit_output_path_filelist(let arg):
            return ["-index-unit-output-path-filelist", arg]
        case .emit_module_doc_path(let arg):
            return ["-emit-module-doc-path", arg]
        case .emit_variant_module_doc_path(let arg):
            return ["-emit-variant-module-doc-path", arg]
        case .emit_dependencies_path(let arg):
            return ["-emit-dependencies-path", arg]
        case .emit_reference_dependencies_path(let arg):
            return ["-emit-reference-dependencies-path", arg]
        case .emit_fixits_path(let arg):
            return ["-emit-fixits-path", arg]
        case .emit_abi_descriptor_path(let arg):
            return ["-emit-abi-descriptor-path", arg]
        case .emit_variant_abi_descriptor_path(let arg):
            return ["-emit-variant-abi-descriptor-path", arg]
        case .emit_module_semantic_info_path(let arg):
            return ["-emit-module-semantic-info-path", arg]
        case .diagnostic_documentation_path(let arg):
            return ["-diagnostic-documentation-path", arg]
        case .dump_api_path(let arg):
            return ["-dump-api-path", arg]
        case .group_info_path(let arg):
            return ["-group-info-path", arg]
        case .prebuilt_module_cache_path(let arg):
            return ["-prebuilt-module-cache-path", arg]
        case .prebuilt_module_cache_path_EQ(let arg):
            return ["-prebuilt-module-cache-path=\(arg)"]
        case .backup_module_interface_path(let arg):
            return ["-backup-module-interface-path", arg]
        case .backup_module_interface_path_EQ(let arg):
            return ["-backup-module-interface-path=\(arg)"]
        case .frontend_parseable_output:
            return ["-frontend-parseable-output"]
        case .primary_file(let arg):
            return ["-primary-file", arg]
        case .block_list_file(let arg):
            return ["-blocklist-file", arg]
        case .triple(let arg):
            return ["-triple", arg]
        case .emit_module_doc:
            return ["-emit-module-doc"]
        case .emit_module_source_info:
            return ["-emit-module-source-info"]
        case .ignore_module_source_info:
            return ["-ignore-module-source-info"]
        case .merge_modules:
            return ["-merge-modules"]
        case .emit_reference_dependencies:
            return ["-emit-reference-dependencies"]
        case .serialize_module_interface_dependency_hashes:
            return ["-serialize-module-interface-dependency-hashes"]
        case .serialize_parseable_module_interface_dependency_hashes:
            return ["-serialize-parseable-module-interface-dependency-hashes"]
        case .tbd_install_name(let arg):
            return ["-tbd-install_name", arg]
        case .tbd_install_name_EQ(let arg):
            return ["-tbd-install_name=\(arg)"]
        case .tbd_current_version(let arg):
            return ["-tbd-current-version", arg]
        case .tbd_current_version_EQ(let arg):
            return ["-tbd-current-version=\(arg)"]
        case .tbd_compatibility_version(let arg):
            return ["-tbd-compatibility-version", arg]
        case .tbd_compatibility_version_EQ(let arg):
            return ["-tbd-compatibility-version=\(arg)"]
        case .tbd_is_installapi:
            return ["-tbd-is-installapi"]
        case .verify:
            return ["-verify"]
        case .verify_additional_file(let arg):
            return ["-verify-additional-file", arg]
        case .verify_additional_prefix(let arg):
            return ["-verify-additional-prefix", arg]
        case .verify_apply_fixes:
            return ["-verify-apply-fixes"]
        case .verify_ignore_unknown:
            return ["-verify-ignore-unknown"]
        case .verify_generic_signatures(let arg):
            return ["-verify-generic-signatures", arg]
        case .show_diagnostics_after_fatal:
            return ["-show-diagnostics-after-fatal"]
        case .enable_cross_import_overlays:
            return ["-enable-cross-import-overlays"]
        case .disable_cross_import_overlays:
            return ["-disable-cross-import-overlays"]
        case .enable_testable_attr_requires_testable_module:
            return ["-enable-testable-attr-requires-testable-module"]
        case .disable_testable_attr_requires_testable_module:
            return ["-disable-testable-attr-requires-testable-module"]
        case .disable_clang_spi:
            return ["-disable-clang-spi"]
        case .enable_target_os_checking:
            return ["-enable-target-os-checking"]
        case .disable_target_os_checking:
            return ["-disable-target-os-checking"]
        case .crosscheck_unqualified_lookup:
            return ["-crosscheck-unqualified-lookup"]
        case .use_clang_function_types:
            return ["-use-clang-function-types"]
        case .print_clang_stats:
            return ["-print-clang-stats"]
        case .serialize_debugging_options:
            return ["-serialize-debugging-options"]
        case .serialized_path_obfuscate(let arg):
            return ["-serialized-path-obfuscate", arg]
        case .empty_abi_descriptor:
            return ["-empty-abi-descriptor"]
        case .no_serialize_debugging_options:
            return ["-no-serialize-debugging-options"]
        case .autolink_library(let arg):
            return ["-autolink-library", arg]
        case .disable_typo_correction:
            return ["-disable-typo-correction"]
        case .disable_implicit_swift_modules:
            return ["-disable-implicit-swift-modules"]
        case .swift_module_file(let arg):
            return ["-swift-module-file=\(arg)"]
        case .swift_module_cross_import(let args):
            return ["-swift-module-cross-import"] + args
        case .module_can_import(let arg):
            return ["-module-can-import", arg]
        case .module_can_import_version(let args):
            return ["-module-can-import-version"] + args
        case .disable_cross_import_overlay_search:
            return ["-disable-cross-import-overlay-search"]
        case .explicit_swift_module_map(let arg):
            return ["-explicit-swift-module-map-file", arg]
        case .const_gather_protocols_file(let arg):
            return ["-const-gather-protocols-file", arg]
        case .placeholder_dependency_module_map(let arg):
            return ["-placeholder-dependency-module-map-file", arg]
        case .import_prescan:
            return ["-import-prescan"]
        case .serialize_dependency_scan_cache:
            return ["-serialize-dependency-scan-cache"]
        case .reuse_dependency_scan_cache:
            return ["-load-dependency-scan-cache"]
        case .validate_prior_dependency_scan_cache:
            return ["-validate-prior-dependency-scan-cache"]
        case .dependency_scan_cache_path(let arg):
            return ["-dependency-scan-cache-path", arg]
        case .dependency_scan_cache_remarks:
            return ["-Rdependency-scan-cache"]
        case .parallel_scan:
            return ["-parallel-scan"]
        case .no_parallel_scan:
            return ["-no-parallel-scan"]
        case .enable_copy_propagation:
            return ["-enable-copy-propagation"]
        case .copy_propagation_state_EQ(let arg):
            return ["-enable-copy-propagation=\(arg)"]
        case .disable_infer_public_concurrent_value:
            return ["-disable-infer-public-sendable"]
        case .Raccess_note(let arg):
            return ["-Raccess-note", arg]
        case .Raccess_note_EQ(let arg):
            return ["-Raccess-note=\(arg)"]
        case .enable_lexical_lifetimes(let arg):
            return ["-enable-lexical-lifetimes=\(arg)"]
        case .enable_lexical_lifetimes_noArg:
            return ["-enable-lexical-lifetimes"]
        case .enable_destroy_hoisting(let arg):
            return ["-enable-destroy-hoisting=\(arg)"]
        case .enable_objc_interop:
            return ["-enable-objc-interop"]
        case .disable_objc_interop:
            return ["-disable-objc-interop"]
        case .enable_experimental_opaque_type_erasure:
            return ["-enable-experimental-opaque-type-erasure"]
        case .enable_objc_attr_requires_foundation_module:
            return ["-enable-objc-attr-requires-foundation-module"]
        case .disable_objc_attr_requires_foundation_module:
            return ["-disable-objc-attr-requires-foundation-module"]
        case .enable_experimental_concurrency:
            return ["-enable-experimental-concurrency"]
        case .enable_experimental_move_only:
            return ["-enable-experimental-move-only"]
        case .enable_experimental_distributed:
            return ["-enable-experimental-distributed"]
        case .enable_experimental_flow_sensitive_concurrent_captures:
            return ["-enable-experimental-flow-sensitive-concurrent-captures"]
        case .disable_experimental_clang_importer_diagnostics:
            return ["-disable-experimental-clang-importer-diagnostics"]
        case .enable_experimental_eager_clang_module_diagnostics:
            return ["-enable-experimental-eager-clang-module-diagnostics"]
        case .enable_experimental_pairwise_build_block:
            return ["-enable-experimental-pairwise-build-block"]
        case .enable_resilience:
            return ["-enable-resilience"]
        case .enable_experimental_async_top_level:
            return ["-enable-experimental-async-top-level"]
        case .public_autolink_library(let arg):
            return ["-public-autolink-library", arg]
        case .enable_experimental_swift_based_closure_specialization:
            return ["-experimental-swift-based-closure-specialization"]
        case .checked_async_objc_bridging(let arg):
            return ["-checked-async-objc-bridging=\(arg)"]
        case .debug_constraints:
            return ["-debug-constraints"]
        case .debug_constraints_attempt(let arg):
            return ["-debug-constraints-attempt", arg]
        case .debug_constraints_on_line(let arg):
            return ["-debug-constraints-on-line", arg]
        case .debug_constraints_on_line_EQ(let arg):
            return ["-debug-constraints-on-line=\(arg)"]
        case .disable_named_lazy_member_loading:
            return ["-disable-named-lazy-member-loading"]
        case .disable_named_lazy_import_as_member_loading:
            return ["-disable-named-lazy-import-as-member-loading"]
        case .dump_requirement_machine:
            return ["-dump-requirement-machine"]
        case .debug_requirement_machine(let arg):
            return ["-debug-requirement-machine=\(arg)"]
        case .dump_macro_expansions:
            return ["-dump-macro-expansions"]
        case .emit_macro_expansion_files(let arg):
            return ["-emit-macro-expansion-files", arg]
        case .analyze_request_evaluator:
            return ["-analyze-request-evaluator"]
        case .analyze_requirement_machine:
            return ["-analyze-requirement-machine"]
        case .requirement_machine_max_rule_count(let arg):
            return ["-requirement-machine-max-rule-count=\(arg)"]
        case .requirement_machine_max_rule_length(let arg):
            return ["-requirement-machine-max-rule-length=\(arg)"]
        case .requirement_machine_max_concrete_nesting(let arg):
            return ["-requirement-machine-max-concrete-nesting=\(arg)"]
        case .requirement_machine_max_split_concrete_equiv_class_attempts(let arg):
            return ["-requirement-machine-max-split-concrete-equiv-class-attempts=\(arg)"]
        case .disable_requirement_machine_concrete_contraction:
            return ["-disable-requirement-machine-concrete-contraction"]
        case .disable_requirement_machine_loop_normalization:
            return ["-disable-requirement-machine-loop-normalization"]
        case .disable_requirement_machine_reuse:
            return ["-disable-requirement-machine-reuse"]
        case .enable_requirement_machine_opaque_archetypes:
            return ["-enable-requirement-machine-opaque-archetypes"]
        case .dump_type_witness_systems:
            return ["-dump-type-witness-systems"]
        case .enable_round_trip_debug_types:
            return ["-enable-round-trip-debug-types"]
        case .disable_round_trip_debug_types:
            return ["-disable-round-trip-debug-types"]
        case .debug_generic_signatures:
            return ["-debug-generic-signatures"]
        case .debug_inverse_requirements:
            return ["-debug-inverse-requirements"]
        case .debug_forbid_typecheck_prefix(let arg):
            return ["-debug-forbid-typecheck-prefix", arg]
        case .experimental_lazy_typecheck:
            return ["-experimental-lazy-typecheck"]
        case .debug_emit_invalid_swiftinterface_syntax:
            return ["-debug-emit-invalid-swiftinterface-syntax"]
        case .debug_cycles:
            return ["-debug-cycles"]
        case .debug_time_function_bodies:
            return ["-debug-time-function-bodies"]
        case .debug_time_expression_type_checking:
            return ["-debug-time-expression-type-checking"]
        case .debug_assert_immediately:
            return ["-debug-assert-immediately"]
        case .debug_assert_after_parse:
            return ["-debug-assert-after-parse"]
        case .debug_crash_immediately:
            return ["-debug-crash-immediately"]
        case .debug_crash_after_parse:
            return ["-debug-crash-after-parse"]
        case .debug_test_dependency_scan_cache_serialization:
            return ["-test-dependency-scan-cache-serialization"]
        case .debugger_support:
            return ["-debugger-support"]
        case .disable_clangimporter_source_import:
            return ["-disable-clangimporter-source-import"]
        case .disable_implicit_concurrency_module_import:
            return ["-disable-implicit-concurrency-module-import"]
        case .disable_implicit_string_processing_module_import:
            return ["-disable-implicit-string-processing-module-import"]
        case .disable_implicit_cxx_module_import:
            return ["-disable-implicit-cxx-module-import"]
        case .disable_arc_opts:
            return ["-disable-arc-opts"]
        case .disable_ossa_opts:
            return ["-disable-ossa-opts"]
        case .disable_sil_partial_apply:
            return ["-disable-sil-partial-apply"]
        case .enable_spec_devirt:
            return ["-enable-spec-devirt"]
        case .enable_async_demotion:
            return ["-enable-experimental-async-demotion"]
        case .enable_throws_prediction:
            return ["-enable-throws-prediction"]
        case .disable_throws_prediction:
            return ["-disable-throws-prediction"]
        case .enable_noreturn_prediction:
            return ["-enable-noreturn-prediction"]
        case .disable_noreturn_prediction:
            return ["-disable-noreturn-prediction"]
        case .disable_access_control:
            return ["-disable-access-control"]
        case .enable_access_control:
            return ["-enable-access-control"]
        case .code_complete_inits_in_postfix_expr:
            return ["-code-complete-inits-in-postfix-expr"]
        case .code_complete_call_pattern_heuristics:
            return ["-code-complete-call-pattern-heuristics"]
        case .disable_autolink_framework(let arg):
            return ["-disable-autolink-framework", arg]
        case .disable_autolink_library(let arg):
            return ["-disable-autolink-library", arg]
        case .disable_autolink_frameworks:
            return ["-disable-autolink-frameworks"]
        case .disable_all_autolinking:
            return ["-disable-all-autolinking"]
        case .disable_force_load_symbols:
            return ["-disable-force-load-symbols"]
        case .disable_diagnostic_passes:
            return ["-disable-diagnostic-passes"]
        case .disable_llvm_optzns:
            return ["-disable-llvm-optzns"]
        case .disable_sil_perf_optzns:
            return ["-disable-sil-perf-optzns"]
        case .disable_swift_specific_llvm_optzns:
            return ["-disable-swift-specific-llvm-optzns"]
        case .disable_llvm_verify:
            return ["-disable-llvm-verify"]
        case .disable_llvm_value_names:
            return ["-disable-llvm-value-names"]
        case .dump_jit(let arg):
            return ["-dump-jit", arg]
        case .enable_llvm_value_names:
            return ["-enable-llvm-value-names"]
        case .enable_anonymous_context_mangled_names:
            return ["-enable-anonymous-context-mangled-names"]
        case .disable_reflection_metadata:
            return ["-disable-reflection-metadata"]
        case .reflection_metadata_for_debugger_only:
            return ["-reflection-metadata-for-debugger-only"]
        case .disable_reflection_names:
            return ["-disable-reflection-names"]
        case .function_sections:
            return ["-function-sections"]
        case .enable_single_module_llvm_emission:
            return ["-enable-single-module-llvm-emission"]
        case .emit_empty_object_file:
            return ["-emit-empty-object-file"]
        case .stack_promotion_checks:
            return ["-emit-stack-promotion-checks"]
        case .stack_promotion_limit(let arg):
            return ["-stack-promotion-limit", arg]
        case .dump_clang_diagnostics:
            return ["-dump-clang-diagnostics"]
        case .dump_clang_lookup_tables:
            return ["-dump-clang-lookup-tables"]
        case .disable_modules_validate_system_headers:
            return ["-disable-modules-validate-system-headers"]
        case .emit_verbose_sil:
            return ["-emit-verbose-sil"]
        case .emit_pch:
            return ["-emit-pch"]
        case .pch_disable_validation:
            return ["-pch-disable-validation"]
        case .disable_sil_ownership_verifier:
            return ["-disable-sil-ownership-verifier"]
        case .suppress_static_exclusivity_swap:
            return ["-suppress-static-exclusivity-swap"]
        case .enable_experimental_static_assert:
            return ["-enable-experimental-static-assert"]
        case .disable_subst_sil_function_types:
            return ["-disable-subst-sil-function-types"]
        case .enable_experimental_named_opaque_types:
            return ["-enable-experimental-named-opaque-types"]
        case .enable_explicit_existential_types:
            return ["-enable-explicit-existential-types"]
        case .enable_experimental_opened_existential_types:
            return ["-enable-experimental-opened-existential-types"]
        case .disable_experimental_opened_existential_types:
            return ["-disable-experimental-opened-existential-types"]
        case .enable_deserialization_recovery:
            return ["-enable-deserialization-recovery"]
        case .disable_deserialization_recovery:
            return ["-disable-deserialization-recovery"]
        case .enable_deserialization_safety:
            return ["-enable-deserialization-safety"]
        case .disable_deserialization_safety:
            return ["-disable-deserialization-safety"]
        case .force_workaround_broken_modules:
            return ["-experimental-force-workaround-broken-modules"]
        case .enable_experimental_string_processing:
            return ["-enable-experimental-string-processing"]
        case .disable_experimental_string_processing:
            return ["-disable-experimental-string-processing"]
        case .enable_experimental_lifetime_dependence_inference:
            return ["-enable-experimental-lifetime-dependence-inference"]
        case .disable_experimental_lifetime_dependence_inference:
            return ["-disable-experimental-lifetime-dependence-inference"]
        case .disable_availability_checking:
            return ["-disable-availability-checking"]
        case .warn_on_potentially_unavailable_enum_case:
            return ["-warn-on-potentially-unavailable-enum-case"]
        case .warn_on_editor_placeholder:
            return ["-warn-on-editor-placeholder"]
        case .report_errors_to_debugger:
            return ["-report-errors-to-debugger"]
        case .enable_swift3_objc_inference:
            return ["-enable-swift3-objc-inference"]
        case .disable_swift3_objc_inference:
            return ["-disable-swift3-objc-inference"]
        case .enable_implicit_dynamic:
            return ["-enable-implicit-dynamic"]
        case .bypass_resilience:
            return ["-bypass-resilience-checks"]
        case .enable_llvm_vfe:
            return ["-enable-llvm-vfe"]
        case .enable_llvm_wme:
            return ["-enable-llvm-wme"]
        case .internalize_at_link:
            return ["-internalize-at-link"]
        case .conditional_runtime_records:
            return ["-conditional-runtime-records"]
        case .mergeable_symbols:
            return ["-mergeable-symbols"]
        case .disable_preallocated_instantiation_caches:
            return ["-disable-preallocated-instantiation-caches"]
        case .disable_readonly_static_objects:
            return ["-disable-readonly-static-objects"]
        case .trap_function(let arg):
            return ["-trap-function", arg]
        case .disable_previous_implementation_calls_in_dynamic_replacements:
            return ["-disable-previous-implementation-calls-in-dynamic-replacements"]
        case .enable_dynamic_replacement_chaining:
            return ["-enable-dynamic-replacement-chaining"]
        case .enable_nskeyedarchiver_diagnostics:
            return ["-enable-nskeyedarchiver-diagnostics"]
        case .disable_nskeyedarchiver_diagnostics:
            return ["-disable-nskeyedarchiver-diagnostics"]
        case .enable_nonfrozen_enum_exhaustivity_diagnostics:
            return ["-enable-nonfrozen-enum-exhaustivity-diagnostics"]
        case .disable_nonfrozen_enum_exhaustivity_diagnostics:
            return ["-disable-nonfrozen-enum-exhaustivity-diagnostics"]
        case .warn_long_function_bodies(let arg):
            return ["-warn-long-function-bodies", arg]
        case .warn_long_function_bodies_EQ(let arg):
            return ["-warn-long-function-bodies=\(arg)"]
        case .warn_long_expression_type_checking(let arg):
            return ["-warn-long-expression-type-checking", arg]
        case .warn_long_expression_type_checking_EQ(let arg):
            return ["-warn-long-expression-type-checking=\(arg)"]
        case .Rmodule_interface_rebuild:
            return ["-Rmodule-interface-rebuild"]
        case .downgrade_typecheck_interface_error:
            return ["-downgrade-typecheck-interface-error"]
        case .enable_volatile_modules:
            return ["-enable-volatile-modules"]
        case .solver_expression_time_threshold_EQ(let arg):
            return ["-solver-expression-time-threshold=\(arg)"]
        case .solver_scope_threshold_EQ(let arg):
            return ["-solver-scope-threshold=\(arg)"]
        case .solver_trail_threshold_EQ(let arg):
            return ["-solver-trail-threshold=\(arg)"]
        case .solver_disable_shrink:
            return ["-solver-disable-shrink"]
        case .solver_disable_splitter:
            return ["-solver-disable-splitter"]
        case .disable_constraint_solver_performance_hacks:
            return ["-disable-constraint-solver-performance-hacks"]
        case .enable_operator_designated_types:
            return ["-enable-operator-designated-types"]
        case .enable_invalid_ephemeralness_as_error:
            return ["-enable-invalid-ephemeralness-as-error"]
        case .disable_invalid_ephemeralness_as_error:
            return ["-disable-invalid-ephemeralness-as-error"]
        case .switch_checking_invocation_threshold_EQ(let arg):
            return ["-switch-checking-invocation-threshold=\(arg)"]
        case .enable_new_operator_lookup:
            return ["-enable-new-operator-lookup"]
        case .disable_new_operator_lookup:
            return ["-disable-new-operator-lookup"]
        case .enable_source_import:
            return ["-enable-source-import"]
        case .enable_throw_without_try:
            return ["-enable-throw-without-try"]
        case .throws_as_traps:
            return ["-throws-as-traps"]
        case .import_module(let arg):
            return ["-import-module", arg]
        case .testable_import_module(let arg):
            return ["-testable-import-module", arg]
        case .print_stats:
            return ["-print-stats"]
        case .check_onone_completeness:
            return ["-check-onone-completeness"]
        case .debugger_testing_transform:
            return ["-debugger-testing-transform"]
        case .disable_debugger_shadow_copies:
            return ["-disable-debugger-shadow-copies"]
        case .disable_concrete_type_metadata_mangled_name_accessors:
            return ["-disable-concrete-type-metadata-mangled-name-accessors"]
        case .disable_standard_substitutions_in_reflection_mangling:
            return ["-disable-standard-substitutions-in-reflection-mangling"]
        case .playground:
            return ["-playground"]
        case .playground_option(let arg):
            return ["-playground-option", arg]
        case .playground_high_performance:
            return ["-playground-high-performance"]
        case .disable_playground_transform:
            return ["-disable-playground-transform"]
        case .pc_macro:
            return ["-pc-macro"]
        case .no_clang_module_breadcrumbs:
            return ["-no-clang-module-breadcrumbs"]
        case .use_jit:
            return ["-use-jit"]
        case .sil_inline_threshold(let arg):
            return ["-sil-inline-threshold", arg]
        case .sil_inline_caller_benefit_reduction_factor(let arg):
            return ["-sil-inline-caller-benefit-reduction-factor", arg]
        case .sil_unroll_threshold(let arg):
            return ["-sil-unroll-threshold", arg]
        case .sil_verify_all:
            return ["-sil-verify-all"]
        case .sil_verify_none:
            return ["-sil-verify-none"]
        case .sil_ownership_verify_all:
            return ["-sil-ownership-verify-all"]
        case .verify_all_substitution_maps:
            return ["-verify-all-substitution-maps"]
        case .sil_debug_serialization:
            return ["-sil-debug-serialization"]
        case .sil_stop_optzns_before_lowering_ownership:
            return ["-sil-stop-optzns-before-lowering-ownership"]
        case .print_inst_counts:
            return ["-print-inst-counts"]
        case .debug_on_sil:
            return ["-sil-based-debuginfo"]
        case .legacy_gsil:
            return ["-gsil"]
        case .print_llvm_inline_tree:
            return ["-print-llvm-inline-tree"]
        case .disable_incremental_llvm_codegeneration:
            return ["-disable-incremental-llvm-codegen"]
        case .ignore_always_inline:
            return ["-ignore-always-inline"]
        case .emit_sorted_sil:
            return ["-emit-sorted-sil"]
        case .cxx_interop_getters_setters_as_properties:
            return ["-cxx-interop-getters-setters-as-properties"]
        case .cxx_interop_disable_requirement_at_import:
            return ["-disable-cxx-interop-requirement-at-import"]
        case .cxx_interop_use_opaque_pointer_for_moveonly:
            return ["-cxx-interop-use-opaque-pointer-for-moveonly"]
        case .use_malloc:
            return ["-use-malloc"]
        case .interpret:
            return ["-interpret"]
        case .verify_type_layout(let arg):
            return ["-verify-type-layout", arg]
        case .external_pass_pipeline_filename(let arg):
            return ["-external-pass-pipeline-filename", arg]
        case .index_system_modules:
            return ["-index-system-modules"]
        case .index_ignore_stdlib:
            return ["-index-ignore-stdlib"]
        case .dump_interface_hash:
            return ["-dump-interface-hash"]
        case .compile_module_from_interface:
            return ["-compile-module-from-interface"]
        case .explicit_interface_module_build:
            return ["-explicit-interface-module-build"]
        case .direct_clang_cc1_module_build:
            return ["-direct-clang-cc1-module-build"]
        case .build_module_from_parseable_interface:
            return ["-build-module-from-parseable-interface"]
        case .typecheck_module_from_interface:
            return ["-typecheck-module-from-interface"]
        case .module_interface_preserve_types_as_written:
            return ["-module-interface-preserve-types-as-written"]
        case .alias_module_names_in_module_interface:
            return ["-alias-module-names-in-module-interface"]
        case .disable_alias_module_names_in_module_interface:
            return ["-disable-alias-module-names-in-module-interface"]
        case .experimental_spi_imports:
            return ["-experimental-spi-imports"]
        case .disable_print_missing_imports_in_module_interface:
            return ["-disable-print-missing-imports-in-module-interface"]
        case .experimental_print_full_convention:
            return ["-experimental-print-full-convention"]
        case .force_public_linkage:
            return ["-force-public-linkage"]
        case .diagnostics_editor_mode:
            return ["-diagnostics-editor-mode"]
        case .validate_tbd_against_ir_EQ(let arg):
            return ["-validate-tbd-against-ir=\(arg)"]
        case .bypass_batch_mode_checks:
            return ["-bypass-batch-mode-checks"]
        case .enable_verify_exclusivity:
            return ["-enable-verify-exclusivity"]
        case .disable_verify_exclusivity:
            return ["-disable-verify-exclusivity"]
        case .disable_legacy_type_info:
            return ["-disable-legacy-type-info"]
        case .disable_generic_metadata_prespecialization:
            return ["-disable-generic-metadata-prespecialization"]
        case .prespecialize_generic_metadata:
            return ["-prespecialize-generic-metadata"]
        case .read_legacy_type_info_path_EQ(let arg):
            return ["-read-legacy-type-info-path=\(arg)"]
        case .type_info_dump_filter_EQ(let arg):
            return ["-type-info-dump-filter=\(arg)"]
        case .swift_async_frame_pointer_EQ(let arg):
            return ["-swift-async-frame-pointer=\(arg)"]
        case .previous_module_installname_map_file(let arg):
            return ["-previous-module-installname-map-file", arg]
        case .enable_type_layouts:
            return ["-enable-type-layout"]
        case .disable_type_layouts:
            return ["-disable-type-layout"]
        case .force_struct_type_layouts:
            return ["-force-struct-type-layouts"]
        case .enable_layout_string_value_witnesses:
            return ["-enable-layout-string-value-witnesses"]
        case .enable_large_loadable_types_reg2mem:
            return ["-enable-large-loadable-types-reg2mem"]
        case .disable_large_loadable_types_reg2mem:
            return ["-disable-large-loadable-types-reg2mem"]
        case .enable_pack_metadata_stack_promotion(let arg):
            return ["-enable-pack-metadata-stack-promotion=\(arg)"]
        case .enable_pack_metadata_stack_promotion_noArg:
            return ["-enable-pack-metadata-stack-promotion"]
        case .disable_layout_string_value_witnesses:
            return ["-disable-layout-string-value-witnesses"]
        case .enable_layout_string_value_witnesses_instantiation:
            return ["-enable-layout-string-value-witnesses-instantiation"]
        case .disable_layout_string_value_witnesses_instantiation:
            return ["-disable-layout-string-value-witnesses-instantiation"]
        case .disable_interface_lockfile:
            return ["-disable-interface-lock"]
        case .bridging_header_directory_for_print(let arg):
            return ["-bridging-header-directory-for-print", arg]
        case .entry_point_function_name(let arg):
            return ["-entry-point-function-name", arg]
        case .target_sdk_version(let arg):
            return ["-target-sdk-version", arg]
        case .target_variant_sdk_version(let arg):
            return ["-target-variant-sdk-version", arg]
        case .target_sdk_name(let arg):
            return ["-target-sdk-name", arg]
        case .candidate_module_file(let arg):
            return ["-candidate-module-file", arg]
        case .use_static_resource_dir:
            return ["-use-static-resource-dir"]
        case .disable_building_interface:
            return ["-disable-building-interface"]
        case .experimental_skip_all_function_bodies:
            return ["-experimental-skip-all-function-bodies"]
        case .experimental_allow_module_with_compiler_errors:
            return ["-experimental-allow-module-with-compiler-errors"]
        case .experimental_skip_non_exportable_decls:
            return ["-experimental-skip-non-exportable-decls"]
        case .bad_file_descriptor_retry_count(let arg):
            return ["-bad-file-descriptor-retry-count", arg]
        case .enable_ast_verifier:
            return ["-enable-ast-verifier"]
        case .disable_ast_verifier:
            return ["-disable-ast-verifier"]
        case .enable_ossa_modules:
            return ["-enable-ossa-modules"]
        case .enable_recompilation_to_ossa_module:
            return ["-enable-recompilation-to-ossa-module"]
        case .enable_sil_opaque_values:
            return ["-enable-sil-opaque-values"]
        case .disable_sil_opaque_values:
            return ["-disable-sil-opaque-values"]
        case .new_driver_path(let arg):
            return ["-new-driver-path", arg]
        case .disable_fine_module_tracing:
            return ["-disable-fine-module-tracing"]
        case .clang_header_expose_decls(let arg):
            return ["-clang-header-expose-decls=\(arg)"]
        case .clang_header_expose_module(let arg):
            return ["-clang-header-expose-module", arg]
        case .weak_link_at_target:
            return ["-weak-link-at-target"]
        case .concurrency_model(let arg):
            return ["-concurrency-model", arg]
        case .concurrency_model_EQ(let arg):
            return ["-concurrency-model=\(arg)"]
        case .enable_stack_protector:
            return ["-enable-stack-protector"]
        case .disable_stack_protector:
            return ["-disable-stack-protector"]
        case .enable_move_inout_stack_protector:
            return ["-enable-move-inout-stack-protector"]
        case .enable_import_ptrauth_field_function_pointers:
            return ["-enable-import-ptrauth-field-function-pointers"]
        case .disable_import_ptrauth_field_function_pointers:
            return ["-disable-import-ptrauth-field-function-pointers"]
        case .enable_lifetime_dependence_diagnostics:
            return ["-enable-lifetime-dependence-diagnostics"]
        case .disable_lifetime_dependence_diagnostics:
            return ["-disable-lifetime-dependence-diagnostics"]
        case .enable_aggressive_reg2mem:
            return ["-enable-aggressive-reg2mem"]
        case .disable_aggressive_reg2mem:
            return ["-disable-aggressive-reg2mem"]
        case .enable_collocate_metadata_functions:
            return ["-enable-collocate-metadata-functions"]
        case .disable_collocate_metadata_functions:
            return ["-disable-collocate-metadata-functions"]
        case .enable_colocate_type_descriptors:
            return ["-enable-colocate-type-descriptors"]
        case .disable_colocate_type_descriptors:
            return ["-disable-colocate-type-descriptors"]
        case .enable_relative_protocol_witness_tables:
            return ["-enable-relative-protocol-witness-tables"]
        case .disable_relative_protocol_witness_tables:
            return ["-disable-relative-protocol-witness-tables"]
        case .enable_fragile_resilient_protocol_witnesses:
            return ["-enable-fragile-relative-protocol-tables"]
        case .disable_fragile_resilient_protocol_witnesses:
            return ["-disable-fragile-relative-protocol-tables"]
        case .enable_async_frame_push_pop_metadata:
            return ["-enable-async-frame-push-pop-metadata"]
        case .disable_async_frame_push_pop_metadata:
            return ["-disable-async-frame-push-pop-metadata"]
        case .enable_async_frame_pointer_all:
            return ["-enable-async-frame-pointer-all"]
        case .disable_async_frame_pointer_all:
            return ["-disable-async-frame-pointer-all"]
        case .enable_split_cold_code:
            return ["-enable-split-cold-code"]
        case .disable_split_cold_code:
            return ["-disable-split-cold-code"]
        case .enable_new_llvm_pass_manager:
            return ["-enable-new-llvm-pass-manager"]
        case .disable_new_llvm_pass_manager:
            return ["-disable-new-llvm-pass-manager"]
        case .enable_profiling_marker_thunks:
            return ["-enable-profiling-marker-thunks"]
        case .disable_profiling_marker_thunks:
            return ["-disable-profiling-marker-thunks"]
        case .enable_objective_c_protocol_symbolic_references:
            return ["-enable-objective-c-protocol-symbolic-references"]
        case .disable_objective_c_protocol_symbolic_references:
            return ["-disable-objective-c-protocol-symbolic-references"]
        case .disable_emit_generic_class_ro_t_list:
            return ["-disable-emit-generic-class-ro_t-list"]
        case .enable_emit_generic_class_ro_t_list:
            return ["-enable-emit-generic-class-ro_t-list"]
        case .enable_deterministic_check:
            return ["-enable-deterministic-check"]
        case .always_compile_output_files:
            return ["-always-compile-output-files"]
        case .input_file_key(let arg):
            return ["-input-file-key", arg]
        case .bridging_header_pch_key(let arg):
            return ["-bridging-header-pch-key", arg]
        case .no_clang_include_tree:
            return ["-no-clang-include-tree"]
        case .cas_fs(let arg):
            return ["-cas-fs", arg]
        case .clang_include_tree_root(let arg):
            return ["-clang-include-tree-root", arg]
        case .clang_include_tree_filelist(let arg):
            return ["-clang-include-tree-filelist", arg]
        case .experimental_spi_only_imports:
            return ["-experimental-spi-only-imports"]
        case .enable_ossa_complete_lifetimes:
            return ["-enable-ossa-complete-lifetimes"]
        case .disable_ossa_complete_lifetimes:
            return ["-disable-ossa-complete-lifetimes"]
        case .enable_ossa_verify_complete:
            return ["-enable-ossa-verify-complete"]
        case .disable_ossa_verify_complete:
            return ["-disable-ossa-verify-complete"]
        case .platform_c_calling_convention(let arg):
            return ["-experimental-platform-c-calling-convention", arg]
        case .platform_c_calling_convention_EQ(let arg):
            return ["-experimental-platform-c-calling-convention=\(arg)"]
        case .disable_sending_args_and_results_with_region_isolation:
            return ["-disable-sending-args-and-results-with-region-based-isolation"]
        case .scanner_module_validation:
            return ["-scanner-module-validation"]
        case .no_scanner_module_validation:
            return ["-no-scanner-module-validation"]
        case .module_load_mode(let arg):
            return ["-module-load-mode", arg]
        case .scanner_output_dir(let arg):
            return ["-scanner-output-dir", arg]
        case .scanner_debug_write_output:
            return ["-scanner-debug-write-output"]
        case .platform_availability_inheritance_map_path(let arg):
            return ["-platform-availability-inheritance-map-path", arg]
        case .disable_experimental_parser_round_trip:
            return ["-disable-experimental-parser-round-trip"]
        }
    }
}
