import First
import Second

public enum ProductShapes {
    public static var combinedValue: Int {
        firstValue + secondValue
    }

    /// What one target of that package could only read because it belongs to
    /// the same package as the other.
    public static var sharedValue: Int {
        sharedAcrossThePackage
    }
}
