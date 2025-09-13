#!/usr/bin/env python3
import json
import re

def categorize_by_title(title):
    """Categorize wallpaper based on its title"""
    title_lower = title.lower()
    categories = []
    
    # Anime/Manga patterns
    if any(word in title_lower for word in ['anime', 'manga', 'otaku', 'kawaii', 'chibi', 'waifu', 'senpai', 'chan', 'kun', 'sama', 'naruto', 'dragon ball', 'one piece', 'attack on titan', 'demon slayer', 'tokyo', 'japan', 'sakura', 'ninja', 'samurai']):
        categories.append('anime')
    
    # Gaming patterns
    if any(word in title_lower for word in ['game', 'gaming', 'gamer', 'fps', 'rpg', 'mmorpg', 'xbox', 'playstation', 'nintendo', 'steam', 'twitch', 'esports', 'controller', 'keyboard', 'mouse', 'pc gaming', 'console', 'arcade', 'pixel', '8-bit', 'retro game', 'minecraft', 'fortnite', 'cod', 'valorant', 'league', 'dota', 'csgo', 'overwatch', 'apex', 'pubg', 'elden ring', 'zelda', 'mario', 'pokemon', 'raid', 'quest', 'boss', 'level up', 'respawn']):
        categories.append('gaming')
    
    # Cars/Automotive patterns
    if any(word in title_lower for word in ['car', 'auto', 'vehicle', 'drive', 'driving', 'race', 'racing', 'drift', 'speed', 'fast', 'ferrari', 'lamborghini', 'porsche', 'bmw', 'mercedes', 'audi', 'tesla', 'mustang', 'corvette', 'gtr', 'supra', 'jdm', 'tuner', 'turbo', 'engine', 'motor', 'wheel', 'tire', 'road', 'highway', 'street race', 'formula', 'f1', 'nascar', 'rally', 'sedan', 'coupe', 'supercar', 'hypercar', 'exotic']):
        categories.append('cars')
    
    # Nature patterns
    if any(word in title_lower for word in ['nature', 'forest', 'tree', 'mountain', 'lake', 'river', 'ocean', 'sea', 'beach', 'sunset', 'sunrise', 'landscape', 'wildlife', 'animal', 'bird', 'flower', 'plant', 'garden', 'park', 'valley', 'hill', 'cliff', 'waterfall', 'stream', 'meadow', 'field', 'grass', 'leaf', 'autumn', 'spring', 'summer', 'winter', 'snow', 'rain', 'cloud', 'sky', 'weather', 'season', 'earth', 'natural', 'outdoor', 'wilderness', 'jungle', 'safari', 'desert', 'canyon', 'glacier']):
        categories.append('nature')
    
    # Space patterns
    if any(word in title_lower for word in ['space', 'cosmos', 'universe', 'galaxy', 'star', 'planet', 'moon', 'sun', 'solar', 'asteroid', 'comet', 'nebula', 'cosmic', 'astro', 'astronomy', 'nasa', 'rocket', 'spaceship', 'spacecraft', 'astronaut', 'orbit', 'mars', 'jupiter', 'saturn', 'venus', 'mercury', 'pluto', 'milky way', 'black hole', 'supernova', 'constellation', 'telescope', 'alien', 'ufo', 'extraterrestrial', 'sci-fi', 'science fiction', 'interstellar', 'celestial']):
        categories.append('space')
    
    # City/Urban patterns
    if any(word in title_lower for word in ['city', 'urban', 'metropolis', 'downtown', 'skyline', 'skyscraper', 'building', 'architecture', 'street', 'avenue', 'boulevard', 'metro', 'subway', 'bridge', 'tower', 'apartment', 'condo', 'office', 'cityscape', 'nightlife', 'neon', 'lights', 'traffic', 'pedestrian', 'sidewalk', 'plaza', 'square', 'district', 'neighborhood', 'town', 'municipal', 'civic', 'metropolitan', 'cosmopolitan', 'new york', 'tokyo', 'london', 'paris', 'dubai', 'singapore', 'hong kong']):
        categories.append('city')
    
    # Fantasy patterns
    if any(word in title_lower for word in ['fantasy', 'magic', 'magical', 'wizard', 'witch', 'sorcerer', 'spell', 'enchant', 'mystic', 'mystical', 'dragon', 'unicorn', 'fairy', 'elf', 'elves', 'dwarf', 'orc', 'goblin', 'troll', 'giant', 'monster', 'creature', 'beast', 'demon', 'angel', 'goddess', 'mythology', 'legend', 'mythical', 'realm', 'kingdom', 'castle', 'dungeon', 'quest', 'adventure', 'sword', 'shield', 'armor', 'knight', 'warrior', 'mage', 'rogue', 'paladin', 'necromancer', 'ethereal', 'supernatural', 'paranormal']):
        categories.append('fantasy')
    
    # Superhero patterns
    if any(word in title_lower for word in ['superhero', 'hero', 'villain', 'marvel', 'dc', 'avenger', 'justice league', 'batman', 'superman', 'spiderman', 'spider-man', 'ironman', 'iron man', 'thor', 'hulk', 'captain america', 'wonder woman', 'flash', 'aquaman', 'black widow', 'hawkeye', 'ant-man', 'doctor strange', 'black panther', 'deadpool', 'wolverine', 'x-men', 'mutant', 'gotham', 'metropolis', 'stark', 'wayne', 'parker', 'kryptonite', 'shield', 'infinity', 'thanos', 'joker', 'comic', 'comics', 'superpower', 'vigilante', 'mask', 'cape']):
        categories.append('superhero')
    
    # Abstract patterns
    if any(word in title_lower for word in ['abstract', 'geometric', 'pattern', 'design', 'art', 'artistic', 'creative', 'color', 'colorful', 'vibrant', 'gradient', 'wave', 'spiral', 'fractal', 'symmetry', 'asymmetry', 'minimalist', 'minimal', 'modern', 'contemporary', 'digital art', 'graphic', 'illustration', 'texture', 'shape', 'form', 'line', 'curve', 'circle', 'square', 'triangle', 'polygon', 'mesh', 'grid', 'mosaic', 'kaleidoscope', 'psychedelic', 'surreal', 'trippy', 'visual', 'aesthetic', '3d', 'render', 'cgi']):
        categories.append('abstract')
    
    # Featured - high quality indicators
    if any(word in title_lower for word in ['4k', '8k', 'hd', 'ultra', 'premium', 'pro', 'best', 'amazing', 'stunning', 'beautiful', 'gorgeous', 'breathtaking', 'spectacular', 'masterpiece', 'epic', 'legendary', 'exclusive', 'limited', 'special', 'deluxe']):
        if categories:  # Only add featured if it has other categories
            categories.append('featured')
    
    # Popular - trending or viral content
    if any(word in title_lower for word in ['trending', 'viral', 'popular', 'hot', 'top', 'best', 'favorite', 'famous', '2024', '2023', 'new', 'latest']):
        if categories:  # Only add popular if it has other categories
            categories.append('popular')
    
    # Special cases and combinations
    if 'cyberpunk' in title_lower:
        categories.extend(['city', 'fantasy', 'gaming'])
    if 'steampunk' in title_lower:
        categories.extend(['fantasy', 'abstract'])
    if 'vaporwave' in title_lower or 'synthwave' in title_lower or 'retrowave' in title_lower:
        categories.extend(['abstract', 'city'])
    if 'lofi' in title_lower or 'lo-fi' in title_lower:
        categories.extend(['anime', 'abstract'])
    
    # Remove duplicates while preserving order
    seen = set()
    unique_categories = []
    for cat in categories:
        if cat not in seen:
            seen.add(cat)
            unique_categories.append(cat)
    
    return unique_categories if unique_categories else ['abstract']  # Default to abstract if no match

# Load the database
print("Loading wallpapers database...")
with open('wallpapers_database.json', 'r') as f:
    db = json.load(f)

wallpapers = db['wallpapers']
total = len(wallpapers)
categorized_count = 0

print(f"Starting categorization of {total} wallpapers...")

# Categorize each wallpaper
for i, wallpaper in enumerate(wallpapers):
    title = wallpaper.get('title', '')
    
    # Get categories based on title
    categories = categorize_by_title(title)
    
    # Set the categories
    wallpaper['categories'] = categories
    
    # Set primary category (the first one)
    wallpaper['primaryCategory'] = categories[0]
    
    categorized_count += 1
    
    # Print progress every 100 wallpapers
    if (i + 1) % 100 == 0:
        print(f"Progress: {i + 1}/{total} wallpapers categorized...")
        print(f"  Last: '{title}' -> {categories}")

# Save the updated database
print(f"\nSaving categorized database...")
with open('wallpapers_database.json', 'w') as f:
    json.dump(db, f, indent=2)

# Print statistics
print("\n" + "="*50)
print("CATEGORIZATION COMPLETE!")
print("="*50)

# Count wallpapers per category
category_counts = {}
for wallpaper in wallpapers:
    for cat in wallpaper.get('categories', []):
        category_counts[cat] = category_counts.get(cat, 0) + 1

print(f"\nTotal wallpapers categorized: {categorized_count}/{total}")
print("\nWallpapers per category:")
for cat, count in sorted(category_counts.items(), key=lambda x: x[1], reverse=True):
    print(f"  {cat:12} : {count:4} wallpapers")

# Find uncategorized (should be 0)
uncategorized = [w for w in wallpapers if not w.get('categories')]
if uncategorized:
    print(f"\nWarning: {len(uncategorized)} wallpapers remain uncategorized")
else:
    print(f"\n✅ All wallpapers have been categorized!")

print("\nDatabase saved to: wallpapers_database.json")