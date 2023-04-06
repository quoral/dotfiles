#!/usr/bin/env python
import click
import re
import subprocess
import json
import random

from PIL import Image
from pathlib import Path
from os import walk

def is_picture_file_ending(f):
    alternatives = [".jpg", ".jpeg", ".png"]
    return any(f.name.lower().endswith(alternative)
               for alternative in alternatives)
def calc_gcd(a, b):
    if b > a:
        return calc_gcd(b, a)
    if a % b == 0:
        return int(b)
    return calc_gcd(b, a % b)

class Picture:
    def __init__(self, path, dimensions):
        self.gcd = calc_gcd(*dimensions)
        self.dimensions = dimensions
        self.path = path

    @property
    def aspect_ratio(self):
        return (int(self.dimensions[0] / self.gcd), int(self.dimensions[1] / self.gcd))

    def is_larger_or_equal_resolution(self, dimensions):
        return self.dimensions[0] >= dimensions[0] and self.dimensions[1] >= dimensions[1]

class Output:
    def __init__(self, output_json):
        self.identifier = "{} {} {}".format(output_json["make"], output_json["model"], output_json["serial"])
        self.name = output_json["name"]
        self.active = output_json["active"]
        if not self.active:
            # Any operations on a non-active screen is pointless
            return
        self.transform = output_json.get("transform", None)
        if self.transform in ("90", "270"):
            self.dimensions = (int(output_json["current_mode"]["height"]), int(output_json["current_mode"]["width"]))
        else:
            self.dimensions = (int(output_json["current_mode"]["width"]), int(output_json["current_mode"]["height"]))
        self.gcd = calc_gcd(*self.dimensions)

    @property
    def aspect_ratio(self):
        return (int(self.dimensions[0] / self.gcd), int(self.dimensions[1] / self.gcd))

    def set_bg(self, picture):
        subprocess.run(["swaymsg", "output {} bg {} fit".format(self.name, picture.path)])

def all_pictures_in_folder(folder):
    path = Path(folder)
    return [f for f in path.rglob("*") if f.is_file() and is_picture_file_ending(f)]

def aspect_ratio_of_image(path):
        gcd = calc_gcd(width, height)
        return int(width / gcd), int(height / gcd)

def get_all_pictures(folder):
    files = all_pictures_in_folder(folder)
    picture_per_aspect_ratio = dict()
    for f in files:
        with Image.open(f) as img:
            width, height = img.size
            image = Picture(f, (width, height))
        if image.aspect_ratio not in picture_per_aspect_ratio:
            picture_per_aspect_ratio[image.aspect_ratio] = []
        picture_per_aspect_ratio[image.aspect_ratio].append(image)
    return picture_per_aspect_ratio

def get_all_outputs():
    command_output = subprocess.run(["swaymsg", "-r", "-t", "get_outputs"], capture_output=True)
    all_outputs = json.loads(command_output.stdout)
    outputs = [Output(single_output) for single_output in all_outputs]
    return [output for output in outputs if output.active]

@click.command()
@click.option('--folder', help='Folder to search.')
def plaster(folder):
    picture_per_aspect_ratio = get_all_pictures(folder)
    print(picture_per_aspect_ratio)
    outputs = get_all_outputs()
    for output in outputs:
        # print(output.aspect_ratio)
        pictures = picture_per_aspect_ratio.get(output.aspect_ratio)
        if not pictures:
            continue
        # print(",".join("{}:{}".format(str(picture.aspect_ratio), picture.path) for picture in pictures))
        pictures_matching = [picture for picture in pictures
                             if picture.is_larger_or_equal_resolution(output.dimensions)]
        picture = random.choice(pictures)
        output.set_bg(picture)



if __name__ == '__main__':
    plaster()
