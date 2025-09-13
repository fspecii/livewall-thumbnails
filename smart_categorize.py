#!/usr/bin/env python3
import json
import re

def smart_categorize(title, wallpaper_id):
    """Smart categorization based on title patterns and ID ranges"""
    title_lower = title.lower()
    categories = []
    
    # Primary categorization based on specific title patterns found in the database
    
    # ANIME titles
    if any(pattern in title_lower for pattern in ['anime', 'manga', 'japanese animation']):
        categories.append('anime')
        # Add featured for high-quality anime
        if 'battle' in title_lower or 'character motion' in title_lower:
            categories.append('featured')
        # Popular anime tend to be in certain ID ranges
        if int(wallpaper_id) % 100 < 20:
            categories.append('popular')
    
    # GAMING titles
    elif any(pattern in title_lower for pattern in ['gaming', 'game scene', 'video game', 'esports']):
        categories.append('gaming')
        # Esports are both gaming and popular
        if 'esports' in title_lower:
            categories.append('popular')
            categories.append('featured')
        # Gaming environments might also be abstract
        if 'environment' in title_lower:
            categories.append('abstract')
    
    # AUTOMOTIVE/CARS
    elif 'automotive' in title_lower or 'car' in title_lower or 'vehicle' in title_lower:
        categories.append('cars')
        # Racing cars are featured
        if 'racing' in title_lower or 'speed' in title_lower:
            categories.append('featured')
    
    # NATURE
    elif 'nature' in title_lower or 'landscape' in title_lower or 'forest' in title_lower:
        categories.append('nature')
        # Scenic nature is often featured
        if 'scenic' in title_lower or 'beautiful' in title_lower:
            categories.append('featured')
    
    # SPACE
    elif any(pattern in title_lower for pattern in ['space', 'cosmic', 'galaxy', 'stellar', 'astronomical']):
        categories.append('space')
        # Space scenes are often abstract too
        categories.append('abstract')
        # Nebulas and galaxies are featured
        if 'nebula' in title_lower or 'galaxy' in title_lower:
            categories.append('featured')
    
    # CITY/URBAN
    elif any(pattern in title_lower for pattern in ['city', 'urban', 'skyline', 'metropolitan']):
        categories.append('city')
        # Night cities are popular
        if 'night' in title_lower or 'neon' in title_lower:
            categories.append('popular')
    
    # FANTASY
    elif any(pattern in title_lower for pattern in ['fantasy', 'magical', 'mythical', 'dragon', 'wizard']):
        categories.append('fantasy')
        # Epic fantasy is featured
        if 'epic' in title_lower or 'legendary' in title_lower:
            categories.append('featured')
    
    # SUPERHERO
    elif 'superhero' in title_lower or 'hero' in title_lower or 'comic' in title_lower:
        categories.append('superhero')
        # Marvel/DC content is popular
        if any(hero in title_lower for hero in ['marvel', 'dc', 'avenger', 'batman', 'spiderman']):
            categories.append('popular')
    
    # ABSTRACT
    elif any(pattern in title_lower for pattern in ['abstract', 'motion graphics', 'visual', 'geometric', 'pattern']):
        categories.append('abstract')
        # Motion graphics are often featured
        if 'motion graphics' in title_lower:
            categories.append('featured')
    
    # Secondary categorization - can add multiple categories
    
    # Check for motion/animation (these are high quality)
    if 'motion' in title_lower or 'animation' in title_lower or 'animated' in title_lower:
        if 'featured' not in categories:
            categories.append('featured')
    
    # Check for "Live Wallpaper" - these are popular
    if 'live wallpaper' in title_lower:
        if 'popular' not in categories:
            categories.append('popular')
    
    # Scene animations are cinematic and featured
    if 'scene' in title_lower and ('animation' in title_lower or 'motion' in title_lower):
        if 'featured' not in categories:
            categories.append('featured')
    
    # Battle/action scenes are popular
    if 'battle' in title_lower or 'action' in title_lower or 'fight' in title_lower:
        if 'popular' not in categories:
            categories.append('popular')
    
    # Environment wallpapers can be multiple categories
    if 'environment' in title_lower:
        # Gaming environments
        if 'gaming' in categories:
            if 'fantasy' not in categories:
                categories.append('fantasy')
        # Natural environments
        elif 'nature' not in categories and not any(cat in categories for cat in ['gaming', 'city']):
            categories.append('nature')
    
    # Default category if none matched
    if not categories:
        # Use ID to determine default category
        id_num = int(wallpaper_id)
        if id_num >= 6000 and id_num < 6500:
            categories.append('anime')  # Early IDs seem to be anime
        elif id_num >= 6500 and id_num < 7500:
            categories.append('gaming')  # Mid IDs are gaming
        elif id_num >= 7500 and id_num < 8000:
            categories.append('nature')  # Nature range
        elif id_num >= 8000 and id_num < 8300:
            categories.append('abstract')  # Abstract range
        else:
            categories.append('abstract')  # Final default
    
    # Remove duplicates while preserving order
    seen = set()
    unique_categories = []
    for cat in categories:
        if cat not in seen:
            seen.add(cat)
            unique_categories.append(cat)
    
    # Limit to max 4 categories per wallpaper for better organization
    return unique_categories[:4]

# Load the database
print("Loading wallpapers database...")
with open('wallpapers_database.json', 'r') as f:
    db = json.load(f)

wallpapers = db['wallpapers']
total = len(wallpapers)

print(f"Starting smart categorization of {total} wallpapers...")

# Categorize each wallpaper with enhanced logic
for i, wallpaper in enumerate(wallpapers):
    title = wallpaper.get('title', '')
    wallpaper_id = wallpaper.get('id', '0')
    
    # Get categories based on smart analysis
    categories = smart_categorize(title, wallpaper_id)
    
    # Set the categories
    wallpaper['categories'] = categories
    
    # Set primary category (the most relevant one)
    wallpaper['primaryCategory'] = categories[0]
    
    # Print progress every 100 wallpapers
    if (i + 1) % 100 == 0:
        print(f"Progress: {i + 1}/{total} wallpapers categorized...")
        # Show last 3 categorizations for verification
        for j in range(max(0, i-2), i+1):
            w = wallpapers[j]
            print(f"  {w['id']}: '{w['title']}' -> {w['categories']}")

# Save the updated database
print(f"\nSaving smart-categorized database...")
with open('wallpapers_database.json', 'w') as f:
    json.dump(db, f, indent=2)

# Print detailed statistics
print("\n" + "="*60)
print("SMART CATEGORIZATION COMPLETE!")
print("="*60)

# Count wallpapers per category
category_counts = {}
multi_category_count = 0
for wallpaper in wallpapers:
    cats = wallpaper.get('categories', [])
    if len(cats) > 1:
        multi_category_count += 1
    for cat in cats:
        category_counts[cat] = category_counts.get(cat, 0) + 1

print(f"\nTotal wallpapers categorized: {total}")
print(f"Wallpapers with multiple categories: {multi_category_count}")

print("\nWallpapers per category:")
for cat, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
    percentage = (count / total) * 100
    print(f"  {cat:12} : {count:4} wallpapers ({percentage:.1f}%)")

# Show category combinations
print("\nMost common category combinations:")
combo_counts = {}
for wallpaper in wallpapers:
    cats = tuple(sorted(wallpaper.get('categories', [])))
    combo_counts[cats] = combo_counts.get(cats, 0) + 1

top_combos = sorted(combo_counts.items(), key=lambda x: x[1], reverse=True)[:10]
for combo, count in top_combos:
    if len(combo) > 1:  # Only show multi-category combos
        print(f"  {' + '.join(combo):40} : {count:3} wallpapers")

# Verify all wallpapers are categorized
uncategorized = [w for w in wallpapers if not w.get('categories')]
if uncategorized:
    print(f"\n⚠️ Warning: {len(uncategorized)} wallpapers remain uncategorized")
    for w in uncategorized[:5]:
        print(f"  - {w['id']}: {w['title']}")
else:
    print(f"\n✅ All {total} wallpapers have been successfully categorized!")

print("\n📁 Database saved to: wallpapers_database.json")
print("🚀 Ready to push to GitHub!")