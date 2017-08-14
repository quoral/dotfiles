import json
import os

from rit import constants
from rit.repo import acquire_repo
from rit.mapping import Mapping, InjectionMappingStatus


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
                              mapping.injection_status.name))


def generate_injection_statuses(mappings):
    return [
        InjectionMappingStatus(mapping, mapping.injection_status)
        for mapping in mappings
    ]


def status_mappings(injection_statuses):
    output = {}
    for mapping, injection_status in injection_statuses:
        if injection_status not in output:
            output[injection_status] = []
        output[injection_status].append(mapping)
    return output
