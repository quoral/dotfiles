import copy
import json
import simplejson
import os
from contextlib import contextmanager

import click

from rit import constants
from rit.mapping import InjectionMappingStatus, Mapping, okay_status
from rit.repo import acquire_repo


@contextmanager
def acquire_mapping_json(writeable=False):
    with acquire_repo() as r:
        mapping_location = os.path.join(r.working_dir, constants.MAP_LOCATION)
        if not os.path.isfile(mapping_location):
            raise FileNotFoundError(
                'File {} not found'.format(constants.MAP_FILENAME))
        with open(mapping_location) as f:
            raw_maps = json.load(f)
        copied_maps = copy.copy(raw_maps)
        yield raw_maps
        if writeable and raw_maps != copied_maps:
            raw_maps_formatted = simplejson.dumps(
                raw_maps, indent=4, sort_keys=True)
            with open(mapping_location, 'w') as f:
                f.write(raw_maps_formatted)


def get_all_mappings():
    with acquire_mapping_json() as raw_maps:
        return [
            Mapping(source, destination)
            for source, destination in raw_maps.items()
        ]


def show_mappings(mappings):
    for m in mappings:
        injection_status = m.injection_status
        color = 'green' if okay_status(injection_status) else 'red'
        click.secho("{}: ".format(m), nl=False)
        click.secho(injection_status.name, fg=color)


def show_mappings_verbose(mappings):
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
