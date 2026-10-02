import CObject
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
}
