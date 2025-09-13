#!/usr/bin/env python3
import json
import webbrowser
import os
from typing import List, Dict, Any

# ANSI color codes for terminal
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def load_database(filename: str) -> Dict[str, Any]:
    with open(filename, 'r') as f:
        return json.load(f)

def save_database(data: Dict[str, Any], filename: str):
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"{Colors.GREEN}✓ Database saved!{Colors.ENDC}")

def display_wallpaper_info(wallpaper: Dict[str, Any], index: int, total: int):
    print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
    print(f"{Colors.BOLD}Wallpaper {index + 1} of {total}{Colors.ENDC}")
    print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}\n")
    
    print(f"{Colors.CYAN}ID:{Colors.ENDC} {wallpaper['id']}")
    print(f"{Colors.CYAN}Title:{Colors.ENDC} {wallpaper['title']}")
    print(f"{Colors.CYAN}Primary Category:{Colors.ENDC} {wallpaper.get('primaryCategory', 'None')}")
    
    current_categories = wallpaper.get('categories', [])
    if current_categories:
        print(f"{Colors.CYAN}Current Categories:{Colors.ENDC} {', '.join(current_categories)}")
    else:
        print(f"{Colors.CYAN}Current Categories:{Colors.ENDC} {Colors.YELLOW}None{Colors.ENDC}")
    
    print(f"\n{Colors.BLUE}Thumbnail:{Colors.ENDC} {wallpaper['thumbnail']}")
    
    if wallpaper.get('downloadUrls'):
        urls = wallpaper['downloadUrls']
        print(f"{Colors.BLUE}HD URL:{Colors.ENDC} {urls.get('hd', 'N/A')}")
        if urls.get('4k'):
            print(f"{Colors.BLUE}4K URL:{Colors.ENDC} {urls['4k']}")

def display_categories(categories: List[Dict[str, Any]]):
    print(f"\n{Colors.BOLD}Available Categories:{Colors.ENDC}")
    print(f"{Colors.YELLOW}{'='*40}{Colors.ENDC}")
    
    for cat in categories:
        print(f"  {Colors.GREEN}{cat['id']:12}{Colors.ENDC} {cat['icon']} {cat['name']}")
    
    print(f"\n{Colors.BOLD}Quick Keys:{Colors.ENDC}")
    print("  1 = anime      6 = city")
    print("  2 = gaming     7 = fantasy")
    print("  3 = cars       8 = superhero")
    print("  4 = nature     9 = abstract")
    print("  5 = space      0 = featured")
    print("              p = popular")

def get_category_by_shortcut(shortcut: str, categories: List[Dict[str, Any]]) -> str:
    shortcuts = {
        '1': 'anime',
        '2': 'gaming',
        '3': 'cars',
        '4': 'nature',
        '5': 'space',
        '6': 'city',
        '7': 'fantasy',
        '8': 'superhero',
        '9': 'abstract',
        '0': 'featured',
        'p': 'popular'
    }
    return shortcuts.get(shortcut, shortcut)

def categorize_wallpapers():
    # Load the database
    db = load_database('wallpapers_database.json')
    wallpapers = db['wallpapers']
    categories = db['categories']
    
    # Track progress
    total = len(wallpapers)
    uncategorized = [w for w in wallpapers if not w.get('categories') or len(w.get('categories', [])) == 0]
    
    print(f"{Colors.BOLD}Wallpaper Categorization Tool{Colors.ENDC}")
    print(f"{Colors.GREEN}Total wallpapers: {total}{Colors.ENDC}")
    print(f"{Colors.YELLOW}Uncategorized: {len(uncategorized)}{Colors.ENDC}")
    print(f"{Colors.CYAN}Already categorized: {total - len(uncategorized)}{Colors.ENDC}")
    
    choice = input(f"\n{Colors.BOLD}Options:{Colors.ENDC}\n1. Categorize uncategorized only\n2. Review all wallpapers\n3. Search by ID\nChoice (1/2/3): ")
    
    if choice == '1':
        wallpapers_to_process = uncategorized
    elif choice == '3':
        search_id = input("Enter wallpaper ID: ")
        wallpapers_to_process = [w for w in wallpapers if search_id in w['id']]
    else:
        wallpapers_to_process = wallpapers
    
    if not wallpapers_to_process:
        print(f"{Colors.GREEN}No wallpapers to process!{Colors.ENDC}")
        return
    
    index = 0
    while index < len(wallpapers_to_process):
        clear_screen()
        wallpaper = wallpapers_to_process[index]
        
        display_wallpaper_info(wallpaper, index, len(wallpapers_to_process))
        display_categories(categories)
        
        print(f"\n{Colors.BOLD}Commands:{Colors.ENDC}")
        print("  Category IDs or shortcuts (can add multiple separated by spaces)")
        print("  'o' = open thumbnail in browser")
        print("  'n' = next wallpaper")
        print("  'b' = previous wallpaper")
        print("  's' = save and continue")
        print("  'q' = save and quit")
        print("  'skip' = skip this wallpaper")
        
        command = input(f"\n{Colors.BOLD}Enter categories or command:{Colors.ENDC} ").strip().lower()
        
        if command == 'q':
            save_database(db, 'wallpapers_database.json')
            print(f"{Colors.GREEN}Saved and exiting...{Colors.ENDC}")
            break
        elif command == 's':
            save_database(db, 'wallpapers_database.json')
            continue
        elif command == 'n' or command == 'skip':
            index += 1
        elif command == 'b':
            index = max(0, index - 1)
        elif command == 'o':
            webbrowser.open(wallpaper['thumbnail'])
        else:
            # Process category input
            input_categories = command.split()
            new_categories = []
            
            for cat_input in input_categories:
                category = get_category_by_shortcut(cat_input, categories)
                if any(c['id'] == category for c in categories):
                    new_categories.append(category)
                else:
                    print(f"{Colors.RED}Invalid category: {cat_input}{Colors.ENDC}")
            
            if new_categories:
                wallpaper['categories'] = new_categories
                # Set primary category to the first one if not set
                if not wallpaper.get('primaryCategory'):
                    wallpaper['primaryCategory'] = new_categories[0]
                
                print(f"{Colors.GREEN}✓ Categories updated: {', '.join(new_categories)}{Colors.ENDC}")
                save_database(db, 'wallpapers_database.json')
                index += 1
                input("Press Enter to continue...")
    
    print(f"\n{Colors.BOLD}Final Statistics:{Colors.ENDC}")
    uncategorized_after = [w for w in wallpapers if not w.get('categories') or len(w.get('categories', [])) == 0]
    print(f"{Colors.GREEN}Categorized: {total - len(uncategorized_after)}{Colors.ENDC}")
    print(f"{Colors.YELLOW}Remaining uncategorized: {len(uncategorized_after)}{Colors.ENDC}")

if __name__ == "__main__":
    try:
        categorize_wallpapers()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Interrupted by user. Changes were saved.{Colors.ENDC}")
    except Exception as e:
        print(f"\n{Colors.RED}Error: {e}{Colors.ENDC}")