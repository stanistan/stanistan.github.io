+++
draft = true
title = "Typed-ish Regex Capture in Swift"
date = 2019-11-14
+++

Over the past couple of months, I've been playing around with [swift], and trying
to build _some kind_ of iOS app. It's been an on again, off again project, but as a
learning experience, it has proven fun since I end up running into different kinds
of problems, and really get to play with the language and libraries.

## So, Why?

I wanted to have a view that was something like, this happened **X days**, or
**X hours** ago, and to have both the number **X**, and the unit, **days** presented
differently in the view.

The standard library has a [`RelativeDateTimeFormatter`], which can be used in a
pretty straight forward way:

```swift
func formattedRelativeDate(for date: Date) -> String {

    // 1. Create your formatter
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .numeric

    // 2. Format `someDate`
    return formatter.localizedString(for: date, relativeTo: Date())
}

let yesterday = /* ya know */
let relativeTime = formattedRelativeDate(for: yesterday)
```

Dang, easy. But I wanted to split up the `relativeTime` into
its parts. I found a good intro into the relatively cumbersome regex
API on [NSHipster].

## The Regex

Sure we can split the string on whitespace and get that over with, but that's
_boring_. A regular expression that can capture the parts that I care about
is this:

```swift
let regexPattern = #"(?<num>\d+)\s+(?<unit>.+)"#
```

The basic way to extract out the match groups (borrowing from the
[nshipster article][nshipster]) is this:

```swift
func findMatches(in relativeTime: String) -> [String : String]? {

    // these match the groups above.
    let groups = ["num", "unit"]

    // create the actual regex
    let regex = try! NSRegularExpression(
        pattern: regexPattern,
        options: []
    )

    // swift regular expressions operate on subranges
    // of strings, so we do this.
    let nsRange = NSRange(
        relativeTime.startIndex..<relativeTime.endIndex,
        in: relativeTime
    )

    if let match = regex.firstMatch(in: relativeTime,
                                    options: [],
                                    range: nsRange) {
        var matches = [String : String]()

        for group in groups {
            let nsRange = match.range(withName: group)
            if nsRange.location != NSNotFound,
                let range = Range(nsRange, in: relativeTime) {
                    matches[group] = "\(relativeTime[range])"
            }
        }

        return matches
    }

    return nil
}
```

This is super specialized, and can be easily factored into something
that accepts both a pattern, and the groups you want to extract.

```swift
func findMatches(in string: String,
                 withPattern pattern: String,
                 withGroups groups: [String])
-> [String : String]? {
    /* ... */
}

//
// And usage:
//

if let matches = findMatches(in: "1 day ago",
                             withPattern: #"(?<num>\d+)\s+(?<unit>.+)"#,
                             withGroups: [ "num", "unit" ])
{
    // we found things!
}
```

## Going further

Sure this works, but there are a couple of things that can be improved:

1. You have to keep the `groups` and `pattern` in sync, it's easy to make this mistake.
2. This returns an untyped, or stringly-typed, bag of data.

_I'm going to iterate on the approach until we get there._

### Enums

So for (1), we can do something by representing each expression as an enum:

```swift
enum Pattern {
    case regular(matches: String)
    case group(matches: String, named: String)
}

struct Regex {
    private let patterns: [Pattern]
    init(_ patterns: Pattern...) {
        self.patterns = patterns
    }
}

// We can leverage swift types to make constructing
// the expressions a bit easier and represent our regex
// like this, otherwise we'll be typing out `Pattern.group(...)`
// and that'd be a bit annoying.
let regex = Regex(
    .group(matches: #"\d+"#, named: "num"),
    .regular(matches: #"\s+"#),
    .group(matches: ".+", named: "unit")
)
```

### Types and KeyPaths

## The Full Implementation

And have something that gives us the actual pattern string:

```swift
func toRegexPattern(_ pattern: Pattern) -> String {
    switch pattern {
    case .regular(let pattern):
        return pattern
    case .group(let pattern, let name):
        return "(?<\(name)>\(pattern))"
}
```







[swift]: https://swift.org
[nshipster]: https://nshipster.com/swift-regular-expressions/
[`RelativeDateTimeFormatter`]: https://developer.apple.com/documentation/foundation/relativedatetimeformatter
