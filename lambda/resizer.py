from PIL import Image
import os

def create_thumbnail(input_path, output_path, size=(128, 128)):
    # Open the image
    with Image.open(input_path) as img:
        # Resize image (in-place)
        img.thumbnail(size)
        # Save the thumbnail
        img.save(output_path)
        print(f"Thumbnail saved to {output_path}")

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
# Build absolute paths for input and output files
input_path = os.path.join(script_dir, "files", "input.png")
output_path = os.path.join(script_dir, "files", "thumbnail.png")

create_thumbnail(input_path, output_path)   
