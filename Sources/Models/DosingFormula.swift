import Foundation

// A safe, deterministic mini-evaluator for compound dosing formulas authored
// in `data/compound_metadata.yaml`.
//
// Variables available to formulas:
//   - weightKg     (Double)
//   - heightCm     (Double)
//   - ageYears     (Double)
//   - weeksOnCycle (Double, defaults to 0)
//
// Operators supported: + - * / ( )
// Built-in functions: min(a,b), max(a,b), clamp(x, lo, hi)
//
// The formula must evaluate to a positive number expressed in the compound's
// `dosingUnit`. The evaluator is intentionally tiny (no closures, no escape
// hatches) so we can ship arbitrary expressions from a YAML file without
// shipping NSPredicate-style injection risk.
struct DosingFormula {
    let expression: String

    enum EvalError: Error, LocalizedError {
        case unknownIdentifier(String)
        case malformed(String)
        case divisionByZero

        var errorDescription: String? {
            switch self {
            case .unknownIdentifier(let n): return "Unknown variable in dosing formula: \(n)"
            case .malformed(let m):         return "Malformed dosing formula: \(m)"
            case .divisionByZero:           return "Division by zero in dosing formula"
            }
        }
    }

    struct Inputs {
        var weightKg: Double
        var heightCm: Double = 0
        var ageYears: Double = 0
        var weeksOnCycle: Double = 0

        func value(for name: String) -> Double? {
            switch name {
            case "weightKg":    return weightKg
            case "heightCm":    return heightCm
            case "ageYears":    return ageYears
            case "weeksOnCycle": return weeksOnCycle
            default:            return nil
            }
        }
    }

    func evaluate(with inputs: Inputs) throws -> Double {
        var parser = Parser(tokens: try Tokenizer.tokenize(expression), inputs: inputs)
        let v = try parser.parseExpression()
        try parser.expectEnd()
        return v
    }

    // MARK: - Tokenizer

    enum Token: Equatable {
        case number(Double)
        case identifier(String)
        case op(Character)        // + - * / ( ) ,
    }

    enum Tokenizer {
        static func tokenize(_ s: String) throws -> [Token] {
            var out: [Token] = []
            var i = s.startIndex
            while i < s.endIndex {
                let ch = s[i]
                if ch.isWhitespace { i = s.index(after: i); continue }
                if ch.isLetter {
                    var j = i
                    while j < s.endIndex && (s[j].isLetter || s[j].isNumber || s[j] == "_") {
                        j = s.index(after: j)
                    }
                    out.append(.identifier(String(s[i..<j])))
                    i = j
                    continue
                }
                if ch.isNumber || ch == "." {
                    var j = i
                    var sawDot = false
                    while j < s.endIndex && (s[j].isNumber || s[j] == ".") {
                        if s[j] == "." { if sawDot { throw EvalError.malformed("multiple decimals") }; sawDot = true }
                        j = s.index(after: j)
                    }
                    guard let n = Double(s[i..<j]) else { throw EvalError.malformed("number") }
                    out.append(.number(n))
                    i = j
                    continue
                }
                if "+-*/(),".contains(ch) {
                    out.append(.op(ch))
                    i = s.index(after: i)
                    continue
                }
                throw EvalError.malformed("unexpected character '\(ch)'")
            }
            return out
        }
    }

    // Recursive-descent parser:
    //   expr   := term (('+' | '-') term)*
    //   term   := unary (('*' | '/') unary)*
    //   unary  := '-' unary | primary
    //   primary := number | identifier | identifier '(' args ')' | '(' expr ')'
    struct Parser {
        let tokens: [Token]
        var pos: Int = 0
        let inputs: Inputs

        init(tokens: [Token], inputs: Inputs) { self.tokens = tokens; self.inputs = inputs }

        mutating func parseExpression() throws -> Double {
            var left = try parseTerm()
            while let t = peek(), case .op(let c) = t, c == "+" || c == "-" {
                pos += 1
                let right = try parseTerm()
                left = (c == "+") ? left + right : left - right
            }
            return left
        }

        mutating func parseTerm() throws -> Double {
            var left = try parseUnary()
            while let t = peek(), case .op(let c) = t, c == "*" || c == "/" {
                pos += 1
                let right = try parseUnary()
                if c == "/" {
                    guard right != 0 else { throw EvalError.divisionByZero }
                    left = left / right
                } else {
                    left = left * right
                }
            }
            return left
        }

        mutating func parseUnary() throws -> Double {
            if case .op("-")? = peek() { pos += 1; return -(try parseUnary()) }
            if case .op("+")? = peek() { pos += 1; return try parseUnary() }
            return try parsePrimary()
        }

        mutating func parsePrimary() throws -> Double {
            guard let t = peek() else { throw EvalError.malformed("unexpected end") }
            switch t {
            case .number(let n):
                pos += 1
                return n
            case .identifier(let name):
                pos += 1
                if case .op("(")? = peek() {
                    pos += 1
                    var args: [Double] = []
                    if case .op(")")? = peek() {
                        pos += 1
                    } else {
                        args.append(try parseExpression())
                        while case .op(",")? = peek() {
                            pos += 1
                            args.append(try parseExpression())
                        }
                        guard case .op(")")? = peek() else { throw EvalError.malformed("missing )") }
                        pos += 1
                    }
                    return try callFunction(name, args: args)
                }
                guard let v = inputs.value(for: name) else {
                    throw EvalError.unknownIdentifier(name)
                }
                return v
            case .op("("):
                pos += 1
                let v = try parseExpression()
                guard case .op(")")? = peek() else { throw EvalError.malformed("missing )") }
                pos += 1
                return v
            case .op(let c):
                throw EvalError.malformed("unexpected '\(c)'")
            }
        }

        func peek() -> Token? { pos < tokens.count ? tokens[pos] : nil }

        mutating func expectEnd() throws {
            if pos != tokens.count { throw EvalError.malformed("trailing tokens") }
        }

        func callFunction(_ name: String, args: [Double]) throws -> Double {
            switch (name, args.count) {
            case ("min", 2):   return Swift.min(args[0], args[1])
            case ("max", 2):   return Swift.max(args[0], args[1])
            case ("clamp", 3): return Swift.min(Swift.max(args[0], args[1]), args[2])
            case ("round", 1): return args[0].rounded()
            case ("floor", 1): return args[0].rounded(.down)
            case ("ceil", 1):  return args[0].rounded(.up)
            default:
                throw EvalError.malformed("unknown function \(name)/\(args.count)")
            }
        }
    }
}
