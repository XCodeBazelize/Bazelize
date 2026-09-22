import LocalBinary

public enum BinaryTarget {
    public static var value: Int {
        Int(local_binary_value())
    }
}
