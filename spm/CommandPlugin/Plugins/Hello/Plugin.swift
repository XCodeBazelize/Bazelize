import PackagePlugin

@main
struct Hello: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        print("Hello from \(context.package.displayName)")

        /// Whatever the user typed after the verb, which is the one thing a
        /// command plugin is given that a build tool plugin is not.
        if !arguments.isEmpty {
            print("Arguments: \(arguments.joined(separator: " "))")
        }
    }
}
