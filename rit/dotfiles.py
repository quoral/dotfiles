import json
import os

from rit import constants
from rit.repo import acquire_repo
from rit.mapping import Mapping


def get_all_mappings(method):
    with acquire_repo() as r:
        mapping_location = os.path.join(r.working_dir, constants.MAP_LOCATION)
        if not os.path.isfile(mapping_location):
            raise FileNotFoundError(
                'File {} not found'.format(constants.MAP_FILENAME))
        with open(mapping_location) as f:
            raw_maps = json.load(f)
        return [
            Mapping(source, destination, method)
            for source, destination in raw_maps.items()
        ]


def show_mappings(mappings):
    for mapping in mappings:
        source = mapping.source
        dest = mapping.destination
        source_exists = "Yes" if os.path.exists(mapping.real_source) else "No"
        if os.path.islink(mapping.user_destination):
            dest_exists = "SymLink"
        elif os.path.exists(mapping.real_destination):
            dest_exists = "Real File"
        else:
            dest_exists = "No"
        fmt_string = ("{}->{} (source exists: `{}` "
                      "dest exists: `{}`, real dest: `{}`, "
                      "Injection status: `{}`)")
        print(
            fmt_string.format(source, dest, source_exists, dest_exists,
                              mapping.real_destination,
                              mapping.verify_injection().name))


def detect_injection_conflicts():
    pass


def inject_mappings(mappings, method):
    for mapping in mappings:
        pass