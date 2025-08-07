import ctypes
import ctypes.wintypes
from pathlib import Path
import os
import sys
import json


def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False


def get_windows_documents_directory():
    CSIDL_PERSONAL = 5       # My Documents
    SHGFP_TYPE_CURRENT = 0   # Get current, not default value

    buf = ctypes.create_unicode_buffer(ctypes.wintypes.MAX_PATH)
    ctypes.windll.shell32.SHGetFolderPathW(
        None, CSIDL_PERSONAL, None, SHGFP_TYPE_CURRENT, buf)
    return Path(buf.value)


def create_user_paths_file():
    """Create user_paths.py file by prompting the user for input"""
    print("user_paths.py file not found. Let's set up your development environment paths.")
    print()

    # Get default Documents directory
    docs_dir = get_windows_documents_directory()
    default_missions = docs_dir / "Arma 3" / "mpmissions"
    default_arma_exe = r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3"

    # Prompt for missions path
    print(f"1. Arma 3 MPMissions folder (default: {default_missions})")
    missions_input = input(
        "   Enter path or press Enter for default: ").strip()
    missions_path = missions_input if missions_input else str(default_missions)

    # Prompt for Paradigm path
    print()
    print("2. Paradigm framework path")
    print("   This should point to your Paradigm installation/repository")
    paradigm_input = input("   Enter path: ").strip()
    while not paradigm_input:
        print("   Paradigm path is required!")
        paradigm_input = input("   Enter path: ").strip()

    # Prompt for Arma executable path
    print()
    print(f"3. Arma 3 installation folder (default: {default_arma_exe})")
    arma_exe_input = input(
        "   Enter path or press Enter for default: ").strip()
    arma_exe_path = arma_exe_input if arma_exe_input else default_arma_exe

    # Prompt for VS Code setup
    print()
    print("4. Set up VS Code development environment? (Y/n)")
    vscode_input = input("   Enter choice (default: Y): ").strip().lower()
    vscode_ide = vscode_input not in ['n', 'no', 'false']

    # Create the user_paths.py content
    content = f'''# Copy and paste your address bar contents for each of your desired locations here.
# Remove "_example" from the name of this file.
MISSIONS_PATH = r"{missions_path}"
PARADIGM_PATH = r"{paradigm_input}"
ARMA_EXE_PATH = r"{arma_exe_path}"  # Path to your Arma 3 installation
VSCODE_IDE = {vscode_ide}  # Set to True to create VS Code tasks.json file for development
'''

    # Write the file
    user_paths_file = Path(__file__).parent / "user_paths.py"
    with open(user_paths_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print()
    print(f"Created user_paths.py with your configuration!")
    print("You can edit this file later if you need to change any paths.")
    print()

    return {
        'MISSIONS_PATH': missions_path,
        'PARADIGM_PATH': paradigm_input,
        'ARMA_EXE_PATH': arma_exe_path,
        'VSCODE_IDE': vscode_ide
    }


def load_user_paths():
    """Load user paths, creating the file if it doesn't exist"""
    user_paths_file = Path(__file__).parent / "user_paths.py"

    if not user_paths_file.exists():
        return create_user_paths_file()

    # Import the existing user_paths module
    try:
        import user_paths
        return {
            'MISSIONS_PATH': getattr(user_paths, 'MISSIONS_PATH', ''),
            'PARADIGM_PATH': getattr(user_paths, 'PARADIGM_PATH', ''),
            'ARMA_EXE_PATH': getattr(user_paths, 'ARMA_EXE_PATH', r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3"),
            'VSCODE_IDE': getattr(user_paths, 'VSCODE_IDE', False)
        }
    except ImportError:
        print("Error: Could not import user_paths.py. The file might be corrupted.")
        print("Recreating the file...")
        return create_user_paths_file()


def setup_vscode_tasks(content_root, user_paths_config):
    """Create .vscode/tasks.json file for development workflow"""
    vscode_dir = content_root / ".vscode"
    vscode_dir.mkdir(exist_ok=True)

    tasks_file = vscode_dir / "tasks.json"

    # Get Arma executable path from user_paths, with fallback
    arma_exe_path = user_paths_config.get(
        'ARMA_EXE_PATH', r"C:\Program Files (x86)\Steam\steamapps\common\Arma 3")

    # Get the mission stem and construct mission paths
    mission_stem = "vn_mikeforce_indev"
    arma_missions_folder = Path(user_paths_config['MISSIONS_PATH'])

    # Mission paths for different maps
    the_bra_mission = arma_missions_folder / \
        f"{mission_stem}.vn_the_bra" / "mission.sqm"
    khe_sanh_mission = arma_missions_folder / \
        f"{mission_stem}.vn_khe_sanh" / "mission.sqm"
    cam_lao_nam_mission = arma_missions_folder / \
        f"{mission_stem}.cam_lao_nam" / "mission.sqm"
    altis_mission = arma_missions_folder / \
        f"{mission_stem}.altis" / "mission.sqm"

    # Define the tasks configuration
    tasks_config = {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "Start Arma 3 (The Bra)",
                "type": "process",
                "options": {
                    "cwd": arma_exe_path
                },
                "command": "arma3_x64",
                "args": [
                    str(the_bra_mission),
                    "-mod=",
                    "-debug",
                    "-skipIntro",
                    "-filePatching",
                    "-noSplash",
                    "-showScriptErrors"
                ],
                "group": {
                    "kind": "test",
                    "isDefault": True
                }
            },
            {
                "label": "Start Arma 3 (Khe Sanh)",
                "type": "process",
                "options": {
                    "cwd": arma_exe_path
                },
                "command": "arma3_x64",
                "args": [
                    str(khe_sanh_mission),
                    "-mod=",
                    "-debug",
                    "-skipIntro",
                    "-filePatching",
                    "-noSplash",
                    "-showScriptErrors"
                ]
            },
            {
                "label": "Start Arma 3 (Cam Lao Nam)",
                "type": "process",
                "options": {
                    "cwd": arma_exe_path
                },
                "command": "arma3_x64",
                "args": [
                    str(cam_lao_nam_mission),
                    "-mod=",
                    "-debug",
                    "-skipIntro",
                    "-filePatching",
                    "-noSplash",
                    "-showScriptErrors"
                ]
            },
            {
                "label": "Start Arma 3 (Altis)",
                "type": "process",
                "options": {
                    "cwd": arma_exe_path
                },
                "command": "arma3_x64",
                "args": [
                    str(altis_mission),
                    "-mod=",
                    "-debug",
                    "-skipIntro",
                    "-filePatching",
                    "-noSplash",
                    "-showScriptErrors"
                ]
            },
            {
                "label": "Stop Arma 3",
                "type": "shell",
                "command": "taskkill",
                "args": [
                    "/F",
                    "/IM",
                    "arma3_x64.exe"
                ],
                "problemMatcher": []
            },
            {
                "label": "RPT Watcher",
                "type": "shell",
                "command": "powershell",
                "args": [
                    "-command",
                    "Get-ChildItem -Path $env:USERPROFILE\\AppData\\Local\\Arma` 3 -Filter *.rpt | Sort-Object LastAccessTime -Descending | Select-Object -First 1 | Get-Content -Tail 1 -Wait -Encoding utf8"
                ],
                "problemMatcher": []
            }
        ]
    }

    # Write the tasks.json file
    with open(tasks_file, 'w', encoding='utf-8') as f:
        json.dump(tasks_config, f, indent=4)

    print(f"Created VS Code tasks.json at: {tasks_file}")
    print(f"Default mission (The Bra): {the_bra_mission}")
    print("You can now use VS Code tasks to:")
    print("  - Start Arma 3 with The Bra mission (default)")
    print("  - Start Arma 3 with other maps (Khe Sanh, Cam Lao Nam, Altis)")
    print("  - Stop Arma 3 quickly")
    print("  - Watch RPT files for changes")


if not is_admin():
    # Re-run the program with admin rights
    ret = ctypes.windll.shell32.ShellExecuteW(
        None, "runas", sys.executable, " ".join(sys.argv), None, 1)
else:
    # Load or create user paths configuration
    user_paths_config = load_user_paths()

    # Validate paths
    paradigm_path = Path(user_paths_config['PARADIGM_PATH'])
    if not paradigm_path.exists():
        print(f"Warning: Paradigm path does not exist: {paradigm_path}")
        print("Please ensure the path is correct in user_paths.py")
        input("Press any key to continue anyway...")

    arma_exe_path = Path(user_paths_config['ARMA_EXE_PATH'])
    if not arma_exe_path.exists():
        print(
            f"Warning: Arma 3 installation path does not exist: {arma_exe_path}")
        print("Please ensure the path is correct in user_paths.py")
        input("Press any key to continue anyway...")

    mission_stem = "vn_mikeforce_indev"

    content_root = Path(__file__).parent
    mission_root = content_root / "mission"
    map_root = content_root / "maps"
    map_folders = [map_path for map_path in map_root.iterdir()
                   if map_path.is_dir()]

    arma_missions_folder = Path(user_paths_config['MISSIONS_PATH'])
    arma_missions_folder.mkdir(parents=True, exist_ok=True)

    def symlink_immediate_children(target, source):
        for path in source.iterdir():
            (target / path.name).symlink_to(path,
                                            target_is_directory=path.is_dir())

    existing_path_found = False
    for map_folder in map_folders:
        target_folder = arma_missions_folder / \
            f"{mission_stem}.{map_folder.name}"
        if target_folder.exists():
            print(f"Existing mission folder exists: {target_folder}")
            existing_path_found = True

        if existing_path_found:
            continue

        target_folder.mkdir()

        print("Symlinking map-specific content...")
        symlink_immediate_children(target_folder, map_folder)
        print("Symlinking mission content...")
        symlink_immediate_children(target_folder, mission_root)
        print("Symlinking paradigm...")
        (target_folder / "paradigm").symlink_to(paradigm_path, target_is_directory=True)

    if existing_path_found:
        print("Cannot create links in Documents/Arma 3 - existing folders found. Please delete these then try again.")

    # Create VS Code tasks.json if VSCODE_IDE is enabled
    vscode_enabled = user_paths_config.get('VSCODE_IDE', False)
    if vscode_enabled and not existing_path_found:
        print("Setting up VS Code development environment...")
        setup_vscode_tasks(content_root, user_paths_config)

    input("Press any key to exit...")
    exit(1 if existing_path_found else 0)
