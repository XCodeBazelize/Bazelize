//
//  SwiftPM.swift
//
//
//  Which generator produces the rules for Swift packages.
//

extension SwiftPM {
    /// Who generates the rules behind `//Packages/<Package>:<Product>`.
    ///
    /// Both modes produce the same labels — the facade is what a target depends
    /// on — so a workspace can be regenerated either way without touching a single
    /// target.
    public enum Mode: String, CaseIterable, Sendable {
        /// `rules_swift_package_manager` generates them in an external repository.
        case rspm
        /// bazelize generates them next to the sources, from the manifests.
        case native
    }
}
