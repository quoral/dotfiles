import json
import os

from rit import constants
from rit.repo import acquire_repo


class Mapping:
    def __init__(self, source, destination):
        self.source = source
        self.destination = destination

    @property
    def real_destination(self):
        return os.path.realpath(os.path.expanduser(self.destination))

    @property
    def real_source(self):
        with acquire_repo() as r:
            return os.path.join(r.working_dir, self.source)

    def __repr__(self):
        return "`{} -> {}`".format(self.source, self.destination)


def get_all_mappings():
    with acquire_repo() as r:
        mapping_location = os.path.join(r.working_dir, constants.MAP_LOCATION)
        if not os.path.isfile(mapping_location):
            raise FileNotFoundError('File {} not found'.format(
                                    constants.MAP_FILENAME))
        with open(mapping_location) as f:
            raw_maps = json.load(f)
        return [Mapping(source, destination) for
                source, destination in raw_maps.items()]


def show_mappings(mappings):
    for mapping in mappings:
        source = mapping.source
        dest = mapping.destination
        source_exists = "Yes" if os.path.exists(mapping.real_source) else "No"
        if os.path.islink(mapping.real_destination):
            dest_exists = "Link"
        elif os.path.exists:
            dest_exists = "Real File"
        else:
            dest_exists = "No"
        fmt_string = ("{}->{} (source exists: `{}` "
                      "dest exists: `{}`, real dest: `{}`)")
        print(fmt_string.format(source, dest, source_exists,
              dest_exists, mapping.real_destination))
