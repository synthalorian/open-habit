name: Pull Request
title: 'pr: '
labels: [triage]
body:
  - type: textarea
    attributes:
      label: Description
      description: A clear and concise description of what this PR changes.
    validations:
      required: true

  - type: textarea
    attributes:
      label: Related Issue
      description: Link any related issues.
      value: 'Fixes #'

  - type: checkboxes
    attributes:
      label: Checklist
      options:
        - label: My code follows the project style guidelines
        - label: I have added tests to cover my change
        - label: I have updated documentation as needed
        - label: I have run `cargo fmt` and `cargo clippy` (Rust) or `dart format .` (Flutter)
