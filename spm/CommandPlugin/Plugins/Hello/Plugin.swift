import PackagePlugin

@main
struct Hello: CommandPlugin {
    func performCommand(context: PluginContext, arguments _: [String]) async throws {
        print("Hello from \(context.package.displayName)")
    }
}
