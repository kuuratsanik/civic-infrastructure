RECOMMENDED KEYBOARD SHORTCUTS FOR VS CODE:

Add these to your keybindings.json (Ctrl+K Ctrl+S):

[
    {
        "key": "ctrl+shift+d",
        "command": "workbench.action.tasks.runTask",
        "args": "Auto-Deploy: All Platforms"
    },
    {
        "key": "ctrl+shift+w",
        "command": "workbench.action.tasks.runTask",
        "args": "Auto-Deploy: Watch Mode"
    },
    {
        "key": "ctrl+shift+s",
        "command": "workbench.action.tasks.runTask",
        "args": "Auto-Deploy: Status Check"
    }
]

QUICK SHORTCUTS:
- Ctrl+Shift+D: Deploy to all platforms
- Ctrl+Shift+W: Start watch mode
- Ctrl+Shift+S: Check deployment status
- Ctrl+Shift+B: Run default build task (Deploy All)
