/// https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md
public protocol Builder {
 associatedtype Expression
 typealias FinalResult = [Expression]
}

enum Either<T, U> {
 case first(T)
 case second(U)
}

indirect enum ResultBuilderTerm<Expression> {
 case expression(Expression)
 case block([ResultBuilderTerm])
 case either(Either<ResultBuilderTerm, ResultBuilderTerm>)
 case optional(ResultBuilderTerm?)
}

@resultBuilder
protocol VariadicBuilder {
 associatedtype Expression
 typealias Component = ResultBuilderTerm<Expression>
 typealias FinalResult = [Expression]
 static func buildFinalResult(_ component: Component) -> FinalResult
}

extension VariadicBuilder {
 static func buildExpression(_ expression: Expression) -> Component {
  .expression(expression)
 }

 static func buildBlock(_ components: Component...) -> Component {
  .block(components)
 }

 static func buildOptional(_ component: Component?) -> Component {
  .optional(component)
 }

 static func buildArray(_ components: [Component]) -> Component {
  .block(components)
 }

 static func buildLimitedAvailability(_ component: Component) -> Component {
  component
 }
}
