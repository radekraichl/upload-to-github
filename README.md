# GitHub Repository Initialization Script

This PowerShell script automates the process of creating a GitHub repository, initializing a Git repository, adding a `.gitignore` template, and generating a `README.md` file. The script performs the following steps:

## Script Features

1. **Check for Git and GitHub CLI:** The script checks whether the `git` and `gh` (GitHub CLI) tools are installed. If any of these tools are missing, the script provides the user with installation instructions.
2. **Authentication:** The script ensures that the user is logged in to GitHub CLI. If the user is not logged in, the script will provide instructions for logging in.
3. **Select `.gitignore` Template:** The script downloads a list of available `.gitignore` templates from a GitHub repository. The user can choose a specific template or leave the `.gitignore` empty.
4. **Choose Repository Visibility:** The script prompts the user to choose the repository visibility (public or private).
5. **Initialize Git Repository:** The script initializes a new Git repository.
6. **Download and Set `.gitignore`:** If the user selects a template for `.gitignore`, the script downloads the corresponding file and adds it to the repository.
7. **Create `README.md` File:** The script allows the user to enter the content for the `README.md` file or use a default template.
8. **Git Commit and Push:** The script adds all files to Git, makes a commit, and then creates a new GitHub repository and pushes the changes to GitHub.

## Requirements

- **Git**: Version control tool. [Install Git](https://git-scm.com/)
- **GitHub CLI (gh)**: Command-line tool for working with GitHub. [Install GitHub CLI](https://cli.github.com/)

## Usage

1. Download or copy this script to your working directory.
2. Open PowerShell and navigate to the folder containing the script.
3. Run the script by executing:

   ```sh
   upload_to_github.bat
   ```
   or, in PowerShell:
   ```sh
   .\upload_to_github.ps1
   ```
