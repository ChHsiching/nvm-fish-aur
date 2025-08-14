# nvm-fish

[![AUR version](https://img.shields.io/aur/version/nvm-fish?logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages/nvm-fish)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

*Read this in other languages: [中文](README_zh-CN.md)*

Fish shell integration for Node Version Manager (nvm) on Arch Linux.

## Overview

This package provides nvm (Node Version Manager) integration for Fish shell on Arch Linux. It allows you to use nvm commands in Fish shell and supports automatic Node.js version switching via .nvmrc files.

### ✨ Key Features

- 🐟 **Complete Fish Shell Integration**: All nvm commands work seamlessly in Fish
- 🎯 **Automatic Version Switching**: Support for .nvmrc files with automatic directory-based switching
- 🔧 **Intelligent Dependency Management**: Automatic bass detection and installation
- 📦 **Zero-Pollution Installation**: No disruption to existing Fish environment
- ⚡ **Ready to Use**: Works immediately after installation, no configuration needed

## Dependencies

- `nvm` - Node Version Manager (from Arch Linux extra repository)
- `fish` - Fish shell
- `bass` - Bash to Fish translation tool (automatically managed)

## Installation

### Install from AUR

```bash
# Using yay or other AUR helper
yay -S nvm-fish

# Or build manually
git clone https://aur.archlinux.org/nvm-fish.git
cd nvm-fish
makepkg -si
```

### Automatic Configuration

No manual configuration needed! The first time you use an nvm command, it will automatically:
- Check and configure bass environment
- Set up Fish shell integration
- Enable automatic version switching

## Quick Start

After installation, simply use nvm in Fish shell:

```fish
# First use will automatically configure environment (including nvm and bass)
nvm --version

# Then you can use all nvm features normally
nvm install node
nvm use node
```

**Automatically handled on first use:**
- ✅ nvm environment check and initialization
- ✅ bass dependency detection and installation
- ✅ Fish shell integration configuration
- ✅ Automatic version switching enabled

## Usage

After installation, simply use nvm commands directly (no configuration steps needed):

```fish
# Check nvm version (first use will automatically set up bass environment)
nvm --version

# Install latest Node.js
nvm install node

# Install specific version
nvm install 18.17.0

# Switch version
nvm use 18

# Set default version
nvm alias default 18

# List installed versions
nvm ls

# List available versions
nvm ls-remote

# Install LTS version
nvm install --lts
```

### Automatic Version Switching

Create a `.nvmrc` file for automatic version switching:

```bash
# Create .nvmrc in project root
echo "18.17.0" > .nvmrc

# nvm will automatically switch to the specified version when you enter the directory
cd your-project
```

## How It Works

This package provides four main Fish functions:

1. `nvm` - Uses bass to call the original bash nvm commands (automatically detects bass environment)
2. `nvm_find_nvmrc` - Find .nvmrc files in current or parent directories
3. `load_nvm` - Automatically load appropriate Node.js version when directory changes
4. `__nvm_setup_bass` and related helper functions - Intelligent bass environment management

### Bass Automatic Management

- **Detect Existing Installation**: First checks if bass is already installed
- **Plugin Manager Support**: Automatically detects and uses fisher, Oh My Fish, fundle
- **Local Fallback**: Downloads source from GitHub and configures locally if no plugin manager
- **Environment Protection**: Local installation doesn't affect user's global Fish configuration

## Troubleshooting

### Bass Related Issues

If bass installation fails, you can install it manually:

```fish
# Install fisher then bass
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
fisher install jorgebucaran/fisher
fisher install edc/bass

# Or install Oh My Fish then bass
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
omf install bass
```

### Function Not Found

If you see "Unknown command" errors:

1. Restart Fish shell: `exec fish`
2. Or reload configuration: `source ~/.config/fish/config.fish`

### Permission Issues

Make sure you have permissions to install packages. Some AUR helpers may require sudo.

## FAQ

**Q: nvm commands don't work after installation?**
A: Please restart your Fish shell or run `exec fish`. This is normal Fish behavior.

**Q: Can this coexist with existing bash nvm installation?**
A: Yes! This package uses the official nvm package as a dependency, so it's fully compatible.

**Q: Automatic version switching doesn't work?**
A: Make sure load_nvm is added to your config.fish. The package handles this automatically, but if you've manually modified your config file, you may need to re-add it.

## Contributing

Contributions are welcome! Please:

1. Fork this repository
2. Create a feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a Pull Request

## License

MIT License - consistent with the upstream nvm project.