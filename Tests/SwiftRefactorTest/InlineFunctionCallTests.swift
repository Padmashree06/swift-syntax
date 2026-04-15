//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftRefactor
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest
import _SwiftSyntaxTestSupport

final class InlineFunctionCallTests: XCTestCase {
  private func functionCallExpr(from markedText: String) throws -> FunctionCallExprSyntax {
    let (markers, source) = extractMarkers(markedText)
    let startOffset = markers["1️⃣"] ?? markers["DEFAULT"] ?? 0

    class FunctionCallFinder: SyntaxAnyVisitor {
      let startOffset: Int
      var found: FunctionCallExprSyntax?

      init(startOffset: Int) {
        self.startOffset = startOffset
        super.init(viewMode: .all)
      }

      override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if found != nil || node.endPosition.utf8Offset < startOffset {
          return .skipChildren
        }

        if node.positionAfterSkippingLeadingTrivia.utf8Offset >= startOffset,
           let call = node.as(FunctionCallExprSyntax.self) {
          found = call
          return .skipChildren
        }

        return .visitChildren
      }
    }

    let finder = FunctionCallFinder(startOffset: startOffset)
    finder.walk(Syntax(Parser.parse(source: source)))
    return try XCTUnwrap(finder.found, "Could not find function call expression after marker", file: #file, line: #line)
  }

  func testInlineSimpleFunctionExpression() throws {
  let input = try functionCallExpr(from: """
    func double(_ x: Int) -> Int {
      return x * 2
    }

    func example() {
      let result = 1️⃣double(5)
    }
    """)

  let expected: ExprSyntax = "5 * 2"

  try assertRefactor(
    input,
    context: (),
    provider: InlineFunctionCall.self,
    expected: expected
  )
}

func testInlineMultipleParametersExpression() throws {
  let input = try functionCallExpr(from: """
    func add(_ a: Int, _ b: Int) -> Int {
      return a + b
    }

    func example() {
      let result = 1️⃣add(10, 20)
    }
    """)

  let expected: ExprSyntax = "10 + 20"

  try assertRefactor(
    input,
    context: (),
    provider: InlineFunctionCall.self,
    expected: expected
  )
}
}


