## 0.1.0

### First Release - Core Functionality

#### Added
- Unified `SerialPort` interface for serial communication
- `SerialManager` for centralized port management
- Support for synchronous and asynchronous reading
- Support for binary and textual data
- Data streams for continuous asynchronous reading
- Flexible configuration (baud rate, data bits, stop bits, parity, flow control)
- Configurable timeouts for read and write operations
- Robust error handling with specific error types:
  - `portNotFound`
  - `portAlreadyOpen`
  - `portClosed`
  - `configurationError`
  - `timeout`
  - `platformUnavailable`
  - `ioError`
  - `permissionDenied`
  - `bufferOverflow`
  - `unknown`
- Example app with language selection (15 languages with flags 🇬🇧 🇮🇹 🇫🇷 etc.)
- Light/Dark/System theme support
- Git Flow workflow with GitVersion configuration
- GitHub Actions CI/CD workflows:
  - Automated testing on PR
  - Automated pub.dev publishing with Google OAuth

#### Supported Platforms
- Windows (FFI implementation)
- Linux (FFI implementation)
- macOS (FFI implementation)
- Android (platform channel + OTG support)
- iOS (platform channel + OTG support)

#### Port Information
- List of available ports
- Device details (vendor ID, product ID, serial number)
- Port status (open/closed)

#### Testing
- Unit tests for core logic
- Integration tests for platform-specific behavior
- E2E tests with happy path, failure path, and edge cases
- Mock serial ports for testing

#### Documentation
- Comprehensive architecture documentation
- Platform-specific implementation guides
- Git Flow and release process documentation
- Google OAuth setup for automated publishing

#### Notes
- First stable release - production-ready
- Ready for use on all supported platforms
