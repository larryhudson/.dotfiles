#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if necessary tools are installed
if ! command_exists node; then
    echo "Node.js is not installed. Please install Node.js and npm before running this script."
    exit 1
fi

if ! command_exists npm; then
    echo "npm is not installed. Please install npm before running this script."
    exit 1
fi

# Prompt for project name
read -p "Enter your project name: " project_name

# Create Next.js project
echo "Creating Next.js project..."
npx create-next-app@latest $project_name --ts --tailwind --app --src-dir --use-npm

# Change to project directory
cd $project_name

# Install shadcn-ui CLI
echo "Installing shadcn-ui CLI..."
npm install -D @shadcn/ui

# Initialize shadcn-ui
echo "Initializing shadcn-ui..."
npx shadcn-ui@latest init --yes

# Prompt user for customization options
read -p "Do you want to customize the installation? (y/n): " customize

if [ "$customize" = "y" ]; then
    echo "Please answer the following questions to customize your installation:"
    npx shadcn-ui@latest init
else
    echo "Using default options for shadcn-ui..."
    echo "y" | npx shadcn-ui@latest init
fi

# Add all shadcn-ui components
echo "Adding all shadcn-ui components..."
npx shadcn-ui@latest add --all

echo "Next.js project with all shadcn-ui components has been set up successfully!"
echo "To start your development server, run:"
echo "cd $project_name && npm run dev"
