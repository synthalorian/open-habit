name: Bug Report

title: 'Bug: '
labels: ['bug', 'triage']
body:
  - type: textarea
    attributes:
      label: Describe the bug
      description: A clear and concise description of what the bug is.
    validations:
      required: true

  - type: textarea
    attributes:
      label: To Reproduce
      description: Steps to reproduce the behavior.
      value: |
        1. Go to '...'
        2. Click on '...'
        3. Scroll to '...'
        4. See error
    validations:
      required: true

  - type: input
    attributes:
      label: Expected behavior
      description: A clear and concise description of what you expected.
    validations:
      required: true

  - type: input
    attributes:
      label: Environment
      description: |
        OS: (e.g., Android 14, iOS 17, Windows 11)
        App version: (e.g., 0.1.0)
      placeholder: |
        OS: Android 14
        App version: 0.1.0
    validations:
      required: true

  - type: textarea
    attributes:
      label: Screenshots / Logs
      description: If applicable, add screenshots or logs to help explain your problem.

  - type: textarea
    attributes:
      label: Additional context
      description: Add any other context about the problem here.
