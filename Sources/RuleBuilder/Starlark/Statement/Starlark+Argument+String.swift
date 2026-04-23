import Foundation

extension String {
    public func property(@StarlarkBuilder builder: () -> Starlark.Value) -> Starlark.Statement.Argument {
        .named(self, builder: builder)
    }
}
