# DeliteAI Cursor Rules Documentation

This document explains the Cursor rules system implemented for the DeliteAI project to ensure consistent, high-quality development across all components.

## Overview

DeliteAI is a complex multi-language project with C++, Python, Swift, Objective-C, and Kotlin components. To maintain consistency and quality across this diverse codebase, we've implemented a comprehensive set of Cursor rules files.

## Rules Files

| File | Purpose | Scope |
|------|---------|--------|
| [`.cursorrules`](.cursorrules) | Main project rules | Project-wide standards and architecture |
| [`.cursorrules-cpp`](.cursorrules-cpp) | C++ development | Core runtime and native components |
| [`.cursorrules-python`](.cursorrules-python) | Python development | Agents, bindings, and simulation |
| [`.cursorrules-mobile`](.cursorrules-mobile) | Mobile development | Android and iOS SDKs |
| [`.cursorrules-docs`](.cursorrules-docs) | Documentation | Sphinx docs and MyST Markdown |
| [`.cursorrules-overview`](.cursorrules-overview) | System overview | Meta-documentation and navigation |

## Quick Start

### For New Contributors
1. Read [`.cursorrules`](.cursorrules) for project understanding
2. Read the specific rules file for your work area
3. Reference [`.cursorrules-overview`](.cursorrules-overview) for navigation

### For AI Assistants
When working with AI coding assistants, reference the appropriate rules:
```
"Please follow the .cursorrules-cpp guidelines for this C++ implementation"
"Use .cursorrules-mobile patterns for this Android feature"
```

## Component Mapping

### C++ Components (use `.cursorrules-cpp`)
- `coreruntime/` - Core AI runtime
- `coreruntime/nimblenet/` - Core components
- `coreruntime/platform/` - Platform abstractions

### Python Components (use `.cursorrules-python`)
- `agents/` - AI agents marketplace
- `nimblenet_py/` - Python simulation framework
- `coreruntime/delitepy/` - Python bindings

### Mobile Components (use `.cursorrules-mobile`)
- `sdks/android/` - Android SDK
- `sdks/ios/` - iOS SDK

### Documentation (use `.cursorrules-docs`)
- `docs/` - Sphinx documentation
- All README files
- API documentation

## Development Workflow

1. **Choose Your Component**: Identify which part of the project you're working on
2. **Read Relevant Rules**: Main rules + component-specific rules
3. **Follow Patterns**: Use the provided code examples and patterns
4. **Test Thoroughly**: Follow testing guidelines for your component
5. **Document Changes**: Update documentation as needed

## Quality Standards

### Code Quality
- Follow language-specific style guides
- Include comprehensive error handling
- Write maintainable, readable code
- Include appropriate tests

### Performance
- Optimize for mobile device constraints
- Consider memory and CPU usage
- Profile performance-critical paths

### Security & Privacy
- Ensure on-device AI processing
- Follow platform security guidelines
- Protect sensitive data appropriately

### Cross-Platform Consistency
- Maintain API parity across platforms
- Use consistent naming conventions
- Test on all supported platforms

## VSCode Extensions

The project includes recommended VSCode extensions in [`.vscode/extensions.json`](.vscode/extensions.json) for:
- C++ development (CMake, clang-format)
- Python development (ruff, Black, pylint)
- Mobile development (Kotlin, Swift)
- Documentation (MyST, Sphinx)
- Build systems and productivity tools

## Contributing

1. Read the [Contributing Guidelines](CONTRIBUTING.md)
2. Follow the relevant Cursor rules for your changes
3. Include DCO sign-off in commits
4. Test thoroughly across platforms
5. Update documentation as needed

## Resources

- [Project Website](https://deliteai.dev/)
- [GitHub Repository](https://github.com/NimbleEdge/deliteAI)
- [Discord Community](https://discord.gg/y8WkMncstk)
- [Contributing Guidelines](CONTRIBUTING.md)

## Support

If you have questions about the rules system or need clarification:
1. Check the [`.cursorrules-overview`](.cursorrules-overview) file
2. Review the specific rules file for your component
3. Ask on Discord or open a GitHub issue
4. Reference existing code examples in the codebase

---

Remember: These rules ensure DeliteAI maintains high quality while enabling privacy-first AI experiences on mobile devices. Every contribution should align with this mission. 