#!/bin/bash
clear
echo "=== AI AGENT PANE ==="
if command -v hermes &> /dev/null; then
    hermes
else
    echo "Ketik hermes di sini nanti"
    bash --rcfile /home/hikaruu/gasken_workspace/workspace-bashrc -i
fi
