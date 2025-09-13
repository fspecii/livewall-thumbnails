# Wallpaper Categorization Guide

## Files Created
- `wallpapers_database.json` - The downloaded wallpaper database (1000 wallpapers)
- `categorize_wallpapers.py` - Interactive tool for manual categorization
- `push_to_github.sh` - Script to push updates to GitHub

## How to Categorize Wallpapers

### 1. Start the Categorization Tool
```bash
python3 categorize_wallpapers.py
```

### 2. Available Categories
- **anime** (1) 🎌 - Anime content
- **gaming** (2) 🎮 - Gaming related
- **cars** (3) 🏎️ - Automotive
- **nature** (4) 🌿 - Nature scenes
- **space** (5) 🚀 - Space and cosmos
- **city** (6) 🏙️ - Urban landscapes
- **fantasy** (7) 🐉 - Fantasy worlds
- **superhero** (8) 🦸 - Superhero content
- **abstract** (9) 🎨 - Abstract art
- **featured** (0) ⭐ - Featured content
- **popular** (p) 🔥 - Popular wallpapers

### 3. Quick Categorization
You can use number shortcuts or type the full category name:
- Type `1` for anime
- Type `2` for gaming
- Type `1 4 9` to assign multiple categories (anime, nature, abstract)

### 4. Commands
- **o** - Open thumbnail in browser to view the wallpaper
- **n** - Next wallpaper
- **b** - Previous wallpaper
- **s** - Save progress
- **q** - Save and quit
- **skip** - Skip current wallpaper

### 5. Workflow Tips
1. Start with "Categorize uncategorized only" to focus on new wallpapers
2. Open thumbnails (press 'o') to see what the wallpaper looks like
3. Assign multiple relevant categories when applicable
4. The tool auto-saves after each categorization

## Pushing to GitHub

### 1. Update Repository URL
Edit `push_to_github.sh` and replace the repository URL:
```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### 2. Run the Push Script
```bash
./push_to_github.sh
```

### 3. The Script Will:
- Validate the JSON file
- Show statistics (total/categorized wallpapers)
- Commit changes with timestamp
- Push to GitHub (with confirmation)

## Statistics
Current Database Status:
- **Total Wallpapers**: 1000
- **Categories**: 11 (anime, gaming, cars, nature, space, city, fantasy, superhero, abstract, featured, popular)

## Example Categorization Session
```
Wallpaper 1 of 1000
====================
ID: 6000
Title: Manga Style Animation
Thumbnail: https://...

Enter categories: 1 7  (assigns anime and fantasy)
✓ Categories updated: anime, fantasy

Wallpaper 2 of 1000
====================
ID: 6001
Title: City Sunset
Thumbnail: https://...

Enter categories: 6 9  (assigns city and abstract)
✓ Categories updated: city, abstract
```

## Notes
- The primary category is automatically set to the first category you assign
- You can assign multiple categories to each wallpaper
- All changes are saved to `wallpapers_database.json`
- Use GitHub to version control your categorization progress