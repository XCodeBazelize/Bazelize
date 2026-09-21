import Testing

struct TbTests {
    @Test
    func testAllTestOptions() throws {
        #expect(
            TestOptions.flag.flags ==
            ["-flag"]
        )
        #expect(
            TestOptions.joined(arg: "A").flags ==
            ["-joinedA"]
        )
        #expect(
            TestOptions.separate(arg: "A").flags ==
            ["-separate", "A"]
        )
        #expect(
            TestOptions.commaJoined(args: ["A", "B"]).flags ==
            ["-commaJoined=A,B"]
        )
        #expect(
            TestOptions.joinedOrSeparate(arg: "A").flags ==
            ["-joinedOrSeparate", "A"]
        )
        
        #expect(
            TestOptions.joinedAndSeparate(arg1: "A", arg2: "B").flags ==
            ["-joinedAndSeparateA", "B"]
        )
    }
}
