# TDD Guard Instructions

<!-- CUSTOMIZE: Replace placeholders with your project-specific details -->

## Project Context

<!-- CUSTOMIZE: Describe your project and test framework -->
This project uses [YOUR_TEST_FRAMEWORK] for testing.

## Test Requirements

<!-- CUSTOMIZE: Describe how tests are structured in your project -->
- Tests live in [YOUR_TEST_DIRECTORY]
- Test files follow the naming convention: [YOUR_CONVENTION]
- Run tests with: [YOUR_TEST_COMMAND]

## Critical Code Paths (Require Tests)

<!-- CUSTOMIZE: List code areas that must always have test coverage -->
<!-- Example:
- Payment processing logic
- Authentication/authorization
- Data transformation/calculation formulas
-->

## Test Mapping

<!-- CUSTOMIZE: Map code areas to specific test files/suites -->
<!-- Example:
| If you modify...          | Run this test              |
|---------------------------|----------------------------|
| src/auth/                 | tests/auth.test.ts         |
| src/payments/             | tests/payments.test.ts     |
| Any API endpoint          | tests/integration/         |
-->

## TDD Workflow

1. Write a failing test that captures the expected behavior
2. Run the test and confirm it fails (RED)
3. Implement the minimum code to make the test pass (GREEN)
4. Refactor with confidence — all tests still pass (REFACTOR)
