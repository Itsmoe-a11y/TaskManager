# TaskManager for iOS

**Windows 11-Style Performance Monitor & Task Manager for TrollStore and Jailbroken Devices**

TaskManager is a native, unsandboxed SwiftUI application for iOS (iOS 15.0+) that brings the full power, visual fidelity, and real-time hardware telemetry of the Windows Task Manager to iOS devices.

---

## Highlights & Capabilities

### 1. 📊 Per-Core CPU Load & Logical Processors Grid
* **All-Core Monitoring**: View real-time load percentages on **every single logical processor** simultaneously (e.g. Core 0 through Core 5 on A15/A16/A17, or 8 cores on M1/M2/M4).
* **Performance vs. Efficiency Core Tagging**: Automatically detects and badges Performance cores (`P-Core`) and Efficiency cores (`E-Core`).
* **Interactive Views**: Switch seamlessly between **Overall Utilization** (60-second full-width chart) and **Logical Processors** (multi-column grid of live mini-charts for each core, just like Windows Task Manager).
* **CPU Hardware Specs**: Shows Apple SoC name, architecture, physical core count, logical core count, socket count, and precise system uptime (`Days:Hours:Minutes:Seconds`).

### 2. 🎮 GPU Utilization & Metal Graphics Engine
* **Real-time 3D & Renderer Tracking**: Measures hardware accelerator utilization via IOKit and Metal.
* **Tiler & Renderer Statistics**: Tracks device utilization, tiler load, and 3D rendering activity.
* **60-Second Rolling Graph**: Windows-style rolling chart displaying GPU load history.

### 3. 🧠 Memory (RAM) Breakdown & Composition
* **Hardware Memory Architecture**: Real-time breakdown of physical RAM into **Wired**, **Active**, **Inactive**, **Compressed**, and **Free** memory pools.
* **Interactive Composition Bar**: Visual multi-segmented bar displaying current memory distribution.
* **Usage & Availability**: Real-time tracked usage in GB and percentages with 60-second history.

### 4. 💾 Storage Speed & APFS Disk I/O
* **Real-time Read & Write Throughput**: Measures active disk read and write speeds in **MB/s**.
* **Disk Active Time**: Displays percentage of time the storage controller is actively processing I/O requests.
* **APFS Storage Capacity**: Clean visual progress bar and diagnostics for total internal storage, used capacity, and free space.

### 5. 📶 Network & Wi-Fi Link Speed
* **Live Bandwidth Throughput**: Real-time download and upload speeds in **KB/s** and **MB/s** across all active network interfaces (`en0`, `pdp_ip0`).
* **Wi-Fi Link Speed (Tx/Rx Rate)**: Detects negotiation link speed (e.g., **866 Mbps** or **1200 Mbps**).
* **Radio & Signal Telemetry**: Displays network SSID, BSSID, RSSI signal strength (dBm & quality percentage), channel number, Wi-Fi band (2.4 GHz / 5 GHz / 6 GHz), and Wi-Fi generation (Wi-Fi 6 / 802.11ax).
* **Network Addressing**: Resolves interface IPv4/IPv6 addresses and gateway details.

### 6. 📋 Process Manager (Windows "End Task")
* **Full System Process List**: Inspect all active apps and background daemons via Darwin `<libproc.h>`.
* **Resource Sorting**: Sort instantly by **CPU %**, **Memory (MB)**, **PID**, or **Name**.
* **Filter Groups**: Toggle between **All Processes**, **User Applications**, and **System Daemons**.
* **End Task Action**: Terminate unresponsive or runaway processes directly with `SIGTERM` or force kill with `SIGKILL`.
* **Process Inspector**: Detailed sheet showing process owner (mobile/root), thread count, resident memory, and virtual memory.

### 7. 💻 System & Thermal Diagnostics
* **Thermal State Tracking**: Live hardware thermal monitor (Nominal, Fair, Serious, Critical).
* **Battery & Power**: Exact battery percentage, charging status, and Low Power Mode detection.
* **Darwin Kernel Details**: Darwin kernel release, build number, and host name.

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────┐
│                      TaskManager (SwiftUI Native)                      │
│  ├── Tab 1: Performance (CPU, Memory, Disk, Wi-Fi, Cellular, GPU)      │
│  ├── Tab 2: Processes (Live CPU%/RAM, Sort, Search, "End Task")        │
│  ├── Tab 3: System (SoC Specs, Darwin Kernel, Thermal, Battery)        │
│  └── Tab 4: Settings (Update Frequency: 0.5s/1s/2s, Theme, Privileges) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────┴────────────────────────────────────┐
│                             Darwin Bridge                              │
│                                                                        │
│  1. Mach Host & CPU Processor Info                                     │
│     - host_processor_info(PROCESSOR_CPU_LOAD_INFO)                     │
│     - Calculates per-core tick deltas (User, System, Idle, Nice)       │
│                                                                        │
│  2. VM Statistics & Memory Pools                                       │
│     - host_statistics64(HOST_VM_INFO64)                                │
│     - Resolves Wired, Active, Inactive, Compressed, and Free RAM       │
│                                                                        │
│  3. IOKit & Metal GPU Monitoring                                       │
│     - Dynamically queries IOAccelerator / AGXAccelerator properties    │
│     - Tracks Device, Renderer, and Tiler utilization                   │
│                                                                        │
│  4. Network & MobileWiFi Link Speed                                    │
│     - getifaddrs byte deltas for real-time throughput                  │
│     - MobileWiFi / ifi_baudrate for Wi-Fi Link Speed, RSSI & Channel   │
│                                                                        │
│  5. Process Control & Inspection                                       │
│     - proc_listallpids, proc_pidinfo, proc_name                        │
│     - POSIX kill(pid, SIGTERM / SIGKILL) for End Task                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Installation

### Via TrollStore (Recommended)
1. Download `TaskManager.tipa` (or `TaskManager.ipa`) from the [Releases](https://github.com/Itsmoe-a11y/TaskManager/releases) tab.
2. Open with **TrollStore** and tap **Install**.
3. Launch **Task Manager** from your Home Screen.

---

## Building from Source

### Prerequisites
* macOS with Xcode 15+
* `xcodegen` (`brew install xcodegen`)
* `ldid` (`brew install ldid`)

### Compile and Package
```bash
git clone https://github.com/Itsmoe-a11y/TaskManager.git
cd TaskManager
chmod +x tools/build-app.sh
./tools/build-app.sh .
```
This produces `TaskManager.ipa` and `TaskManager.tipa` signed with TrollStore entitlements in the project root.

---

## License

This project is licensed under the MIT License.
