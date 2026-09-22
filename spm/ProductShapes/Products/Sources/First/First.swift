public let firstValue = 20

/// `package` access: visible to the targets of this package and to nothing
/// else. Which targets those are is the package's name, so a build that does
/// not say what package a target belongs to cannot compile the use of it.
package let firstPackageValue = 20
