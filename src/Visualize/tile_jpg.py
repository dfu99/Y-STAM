# From https://stackoverflow.com/questions/69804229/tiling-images-by-batch-using-python-pil-fill-background-image-repeatedly-by-fol

# Imports
import os
from PIL import Image
Image.MAX_IMAGE_PIXELS = None

# Grid shape
grid = (5, 6)


# Working directories
INPUT_DIRS = [r'/home/dan/Documents/temp/radial_majority(16)_01']
for i in range(len(INPUT_DIRS)):
    INPUT_DIR = INPUT_DIRS[i]
    OUTPUT_DIR = r'/home/dan/Documents/temp/results'
    IMAGE_EXT = ('.jpg', '.jpeg', '.png', '.gif')

    # Get all the image paths
    all_images = []
    for subdir, dirs, files in os.walk(INPUT_DIR):
        for file in files:
            if file.endswith(IMAGE_EXT):
                image_path = os.path.join(subdir, file)
                all_images.append(image_path)
    all_images = sorted(all_images)

    # Remove some to make the layout look better
    while True:
        item_buffer = None
        for i, item in enumerate(all_images):
            if item[-6] == '5' and item[-10:-4] != '000050':
                item_buffer = i
                break
            # elif item[-10:-4] == '001700':
            #     item_buffer = i
            #     break
            # elif item[-10:-4] == '001900':
            #     item_buffer = i
            #     break
        if item_buffer:
            all_images.remove(all_images[i])
        else:
            break

    # Print out all the image paths to console just to make sure we got them all
    print(len(all_images))
    for line in all_images:
        print(line)


    # Create an iterator
    image_it = iter(all_images)
    image_path = next(image_it)

    # Get single tile image dimensions
    bg = Image.open(image_path)
    bg_w, bg_h = bg.size

    left = bg_w*0.15
    top = bg_h*0.05
    bottom = bg_h*0.95
    right = bg_w*0.85

    bg = bg.crop((left, top, right, bottom))
    bg_w, bg_h = bg.size
    print(bg.size)


    # Output image
    new_im = Image.new('RGB', (bg_w * grid[0], bg_h * grid[1]))
    w, h = new_im.size

    # Iterate through each position of the output image
    try:    
        for j in range(0, bg_h * grid[1], bg_h):
            for i in range(0, bg_w * grid[0], bg_w):
                new_im.paste(bg, (i, j))
                image_path = next(image_it)
                bg = Image.open(image_path)
                bg = bg.crop((left, top, right, bottom))
    except StopIteration:
        pass

    # Save the output
    new_im.save(os.path.join(OUTPUT_DIR, file))