//class Option<list<string> prefixes, string name, OptionKind kind> {
//  string EnumName = ?; // Uses the def name if undefined.
//  list<string> Prefixes = prefixes;
//  string Name = name;
//  OptionKind Kind = kind;
//  // Used by MultiArg option kind.
//  int NumArgs = 0;
//  string HelpText = ?;
//  list<HelpTextVariant> HelpTextsForVariants = [];
//  string MetaVarName = ?;
//  string Values = ?;
//  code ValuesCode = ?;
//  list<OptionFlag> Flags = [];
//  list<OptionVisibility> Visibility = [DefaultVis];
//  OptionGroup Group = ?;
//  Option Alias = ?;
//  list<string> AliasArgs = [];
//  code MacroPrefix = "";
//  code KeyPath = ?;
//  code DefaultValue = ?;
//  code ImpliedValue = ?;
//  code ImpliedCheck = "false";
//  code ShouldParse = "true";
//  bit ShouldAlwaysEmit = false;
//  code NormalizerRetTy = ?;
//  code NormalizedValuesScope = "";
//  code Normalizer = "";
//  code Denormalizer = "";
//  code ValueMerger = "mergeForwardValue";
//  code ValueExtractor = "extractForwardValue";
//  list<code> NormalizedValues = ?;
//}

//struct Option: Equatable {
//    let prefixes: [String]
//    let name: String
//    let kind: OptionKind
//    let enumName: String?
//    let helpText: String?
//    let metaVarName: String?
//    let values: String?
//    let valuesCode: String?
//    let flags: [OptionFlag]
//}
