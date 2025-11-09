#!/bin/bash
# Test if the runtime installer module outputs a valid script
echo "Testing runtime installer module output..."
echo ""
echo "Module install_script output:"
echo "=============================="
# This would need terraform output, but we can check if the file would be created
if [ -f "build/install-runtimes.sh" ]; then
    echo "✅ install-runtimes.sh EXISTS"
    echo ""
    echo "First 20 lines:"
    head -20 build/install-runtimes.sh
else
    echo "❌ install-runtimes.sh DOES NOT EXIST"
    echo "   This file is created by terraform during 'apply'"
fi
