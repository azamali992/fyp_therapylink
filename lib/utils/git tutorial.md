 t# Git and GitHub Tutorial for Flutter Projects

## Initial Setup and Configuration

### Setting up Git Identity
```bash
# Configure your email globally for all Git repositories
git config --global user.email "your.email@example.com"

# Configure your username globally for all Git repositories
git config --global user.name "yourusername"

# Initialize a new Git repository in current directory
git init

# Connect your local repository to a remote GitHub repository
git remote add origin https://github.com/yourusername/repository-name.git

# Rename the default branch to 'main' (modern naming convention)
git branch -M main

# Check the current status of your repository (modified files, staged changes, etc.)
git status

# Stage all changed files for commit
git add .                    

# Stage a specific file for commit
git add filename.dart        

# Create a commit with a message describing your changes
git commit -m "descriptive message"

# Create a commit while skipping any pre-commit hooks
git commit -m "message" -n   

# Push your commits to the current branch on remote
git push                     

# First time push and set up tracking for main branch
git push -u origin main     

# Create and switch to a new branch
git checkout -b feature-name     

# Switch to the main branch
git checkout main               

# Delete a local branch after it's merged
git branch -d feature-name      

# First time pushing a new branch to remote and set up tracking
git push --set-upstream origin feature-name    

# Subsequent pushes after branch tracking is set up
git push                                       

# Pull changes and rebase local commits on top (cleaner history)
git pull --rebase origin main    

# Pull changes and merge them with local changes
git pull                         

# Common workflow for starting new feature:
# 1. Switch to main branch
git checkout main

# 2. Get latest changes from remote
git pull --rebase origin main

# 3. Create new feature branch
git checkout -b feature/new-feature

# 4. After making changes, stage them
git add .

# 5. Commit changes
git commit -m "Add new feature"

# 6. Push new branch to remote
git push --set-upstream origin feature/new-feature

# Updating feature branch with main branch changes:
# 1. Switch to main
git checkout main

# 2. Get latest changes
git pull --rebase origin main

# 3. Switch to feature branch
git checkout feature/new-feature

# 4. Rebase feature branch on top of main
git rebase main

# After resolving merge conflicts, continue rebase
git add .                    # Stage resolved files
git rebase --continue        # Continue the rebase process

# Undo the last commit but keep the changes staged
git reset --soft HEAD~1    

# Discard all local changes (dangerous - cannot be undone!)
git reset --hard HEAD      

# Discard changes in a specific file
git checkout -- file.dart