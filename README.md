# Zopfli Compression Script

A robust Bash script for compressing files and directories using tar and zopfli. This tool detects your OS, handles dependencies automatically, and provides real-time progress feedback as it packages and compresses your data.

## Features

- **Cross-Platform OS Detection:** Supports Linux, macOS, and Windows (via compatible environments).
- **Automated Dependency Management:** Prompts to install zopfli if it's missing.
- **Progress Feedback:** Real-time visual indicators during file copying, archiving, and compression.
- **Flexible Options:** Configure output directory, compression level (1–100), and permission preservation.

## Prerequisites

- **Bash Shell:** Ensure you are running the script in a Bash environment.
- **tar:** Available by default on most Unix-like systems.
- **zopfli:** The script will prompt to install if not found.

## Installation

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/aznironman/zcompress-script.git
   cd zcompress-script
   ```

2. **Copy the script to your desired location (i.e. your scripts folder)**

   ```bash
   cp zcompress.sh ~/scripts/
   ```

3. **Make the Script Executable:**

   ```bash
   chmod +x compress.sh
   ```

4. (Optional) **Add the script to your PATH:**

   ```bash
   sudo ln -s ~/scripts/compress.sh /usr/local/bin/compress
   ```

5. **Run the script:**

   ```bash
   compress.sh [-o output_dir] [-c compression_level] [-p] archive_name target1 [target2 ... targetN]
   ```

## Usage

Run the script with the following syntax:

```bash
./compress.sh [-o output_dir] [-c compression_level] [-p] archive_name target1 [target2 ... targetN]
```

- `-o`: Specify the output directory (default: current directory).
- `-c`: Set the compression level (number between 1 and 100, default: 15).
- `-p`: Preserve file permissions when copying files.
- `archive_name`: The name of the resulting archive (without extension).
- `target`: One or more files or directories to compress.

Example:

```bash
./compress.sh -o /tmp -c 20 my_archive ./folder1 ./file2.txt
```

## Script Structure

- **OS Detection:** Determines the operating system to customize dependency prompts.
- **Dependency Check:** Verifies and offers installation for zopfli.
- **Progress Functions:** Provides visual feedback during long-running operations.
- **Compression Pipeline:** Copies targets to a temporary directory, creates a tar archive, compresses it with zopfli, and verifies the archive integrity.

## Configuration

Customize the behavior by using command-line flags:

- **Output Directory:** Use `-o` to define where the archive is saved.
- **Compression Level:** Adjust with `-c` for finer control over compression.
- **Permissions:** Include `-p` to retain original file permissions.

## Development

This script is designed for efficiency and simplicity. Contributions, improvements, and feature requests are welcome.

## License

MIT License

© 2025 Clark & Burke, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

## Author Contact Information

- Email: <contact@clarkburke.com>
- GitHub: [Clark & Burke, LLC](https://github.com/yourusername)
