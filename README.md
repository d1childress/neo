# neo

A modern, all-in-one network utility app for macOS, built with SwiftUI. Neo provides a suite of tools for network diagnostics, monitoring, and troubleshooting, all in a beautiful, unified interface.

---

## Table of Contents
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Features

Neo includes the following network tools, accessible via tabs:

- **Info**: View detailed information and statistics for your network interfaces (IP, MAC, DNS, gateway, traffic stats, etc.).
- **Netstat**: Run various `netstat` commands to inspect routing tables, sockets, protocol stats, and multicast info.
- **Ping**: Test connectivity to a host with IPv4/IPv6 support and customizable ping count.
- **Lookup**: Perform DNS lookups using `dig`, `nslookup`, or macOS directory services.
- **Speed Test**: Benchmark your internet connection's download and upload speeds, with advanced diagnostics.
- **Trace**: Trace the route to a host using `traceroute` (IPv4/IPv6).
- **Port Scan**: Scan a host for open TCP ports in a specified range, with optional verbose output.
- **Whois**: Query domain registration info from various whois servers.
- **SSH**: Connect to remote servers via SSH with support for both password and key-based authentication.

All tools feature a dark, modern UI with monospaced output, copy-to-clipboard, and responsive layouts.

---

## Screenshots

Neo provides a comprehensive suite of network utilities with a modern, dark-themed interface:

### Speed Test
![Speed Test](images/speed-test-view.png)
*Benchmark your internet connection with download/upload speed tests, featuring advanced diagnostics and real-time results.*

### DNS Lookup
![DNS Lookup](images/lookup-view.png)
*Perform DNS lookups with support for multiple providers, showing detailed resolution information including IPv4/IPv6 addresses.*

### SSH Connection
![SSH Connection](images/ssh-view.png)
*Connect to remote servers via SSH with support for both password and key-based authentication, featuring a clean connection interface.*

### Network Ping
![Network Ping](images/ping-view.png)
*Test network connectivity with customizable ping counts, showing detailed response times and statistics.*

### Route Tracing
![Route Tracing](images/trace-view.png)
*Trace network routes to identify connectivity issues and view the path data takes through the internet.*

---

**Additional Views Available:**
- **Info Tab**: Detailed network interface information and statistics
- **Netstat Tab**: Network socket and routing table information  
- **Port Scan Tab**: TCP port scanning with customizable ranges
- **Whois Tab**: Domain registration information lookup

---

## Installation

### Prerequisites
- macOS 12.0 or later
- Xcode 14 or later

### Build & Run
1. Clone the repository:
   ```sh
   git clone <repo-url>
   cd neo
   ```
2. Open `neo/neo.xcodeproj` in Xcode.
3. Select the `neo` scheme and your target Mac device.
4. Press **Run** (⌘R) to build and launch the app.

---

## Usage

Each tool is available as a tab in the main window:

- **Info**: Select a network interface to view its details and live statistics. Click 'Refresh' to update.
- **Netstat**: Choose the type of network info (routing table, sockets, etc.) and run the command. Output is shown in a scrollable, copyable area.
- **Ping**: Enter a host, select IPv4/IPv6, and set the ping count. Start/stop pings and copy results.
- **Lookup**: Enter a domain/IP, select a provider (`dig`, `nslookup`, or `dscacheutil`), and view DNS records.
- **Speed Test**: Run download/upload/both tests, view speeds, and toggle advanced diagnostics.
- **Trace**: Enter a host, select IPv4/IPv6, and trace the route. Start/stop as needed.
- **Port Scan**: Enter a host, set port range, and scan for open TCP ports. Enable verbose for closed port info.
- **Whois**: Enter a domain, select a whois server, and fetch registration info.
- **SSH**: Enter host, port, username, and choose authentication method (password or SSH key). Connect to remote servers and execute commands interactively.

All results can be copied to the clipboard with a single click.

---

## Testing

### Unit Tests
- Located in `neo/neoTests/neoTests.swift`.
- To run unit tests:
  1. Open the project in Xcode.
  2. Select the `neo` scheme.
  3. Press **Command-U** to run all tests.

### UI Tests
- Located in `neo/neoUITests/`.
- To run UI tests:
  1. Open the project in Xcode.
  2. Select the `neo` scheme.
  3. Press **Command-U** to run all tests (UI and unit).

---

## Contributing

Contributions are welcome! Please open issues or pull requests for bug fixes, new features, or suggestions.

---

## License

[MIT](LICENSE) © d1demos
