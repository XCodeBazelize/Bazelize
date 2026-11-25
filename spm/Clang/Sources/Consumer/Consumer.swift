import CHiddenOnly
import CMany
import CManyExtra
import CObject
import CPair
import CPairInner
import CPairInner.Extras
import CPairParts.CPairPartA
import CxxLib

public enum Consumer {
    public static var value: Int32 {
        CObject.value()
    }

    public static var flag: Bool {
        CObject.flag()
    }

    public static var internalValue: Int32 {
        CObject.internalValue()
    }

    public static var greeting: String? {
        CObject.greeting()
    }

    public static var assembly: Int32 {
        assembly_value()
    }

    public static var twice: Int32 {
        demo.twice(21)
    }

    public static var objectiveCxxLength: Int32 {
        demo.objectiveCxxLength()
    }

    /// The module the target is named after, and the one its nested map
    /// declares: both are the same target's.
    public static var pair: (outer: Int32, inner: Int32) {
        (pair_outer_value(), pair_inner_value())
    }

    /// What the rest of the nested map declares: a header it excludes, which
    /// its own header includes textually, and a submodule over a directory.
    public static var pairInner: (detail: Int32, extras: Int32) {
        (pair_inner_detail_value(), pair_inner_extras_value())
    }

    /// A submodule clang infers from the umbrella of a map in a real
    /// subdirectory.
    public static var pairPart: Int32 {
        pair_part_a_value()
    }

    /// Both modules of the map `CMany` ships.
    public static var many: (total: Int32, extra: Int32) {
        (many_total(), many_extra_value())
    }

    /// The one module `CHidden`'s map declares, built over a target whose map
    /// declares none.
    public static var hiddenOnly: Int32 {
        hidden_only_value()
    }
}
