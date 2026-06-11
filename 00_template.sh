#!/bin/bash

set -e 

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo."
  exit 1
fi

echo "🚀 Starting ..."



echo "🎉 All done!"

