# ⌨️ Keyboard Layout Switcher

A PowerShell tool for switching between Japanese (JIS) and US (ANSI) keyboard layouts on Windows 11/10.

## 🚀 Quick Start

1. **Download** the script: `keyboard-switcher.ps1`
2. **Run** the script (double-click or right-click → "Run with PowerShell")
3. **Allow** administrator privileges when prompted
4. **Select** your desired layout and restart option

## 📋 Requirements

- **OS**: Windows 10/11
- **PowerShell**: 5.1 or later (built-in)
- **Permissions**: Administrator privileges (automatically requested)

## 🎯 Supported Layouts

| Layout | Description | Keys |
|--------|-------------|------|
| **Japanese (JIS)** | Japanese Industrial Standard | 106/109 keys |
| **US (ANSI)** | American National Standards Institute | 101/102 keys |

## 📖 Usage

### Interactive Mode
```powershell
.\keyboard-switcher.ps1
```

### Command Line Mode
```powershell
# Switch to Japanese layout
.\keyboard-switcher.ps1 -Layout japanese

# Switch to US layout  
.\keyboard-switcher.ps1 -Layout english
```
