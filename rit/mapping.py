import os
from collections import namedtuple
from enum import Enum, auto

import click

from rit.constants import Method
from rit.repo import acquire_repo


class InjectionStatus(Enum):
    AlreadyInjected = auto()
    CanInject = auto()
    InjectionConflict = auto()
    UnkownStatus = auto()


def okay_status(injection_status):
    return (injection_status is InjectionStatus.CanInject
            or injection_status is InjectionStatus.AlreadyInjected)


InjectionMappingStatus = namedtuple('InjectionMappingStatus',
                                    ['mapping', 'injection_status'])


class Mapping:
    def __init__(self, source, destination, method=Method.LINK):
        self.source = source
        self.destination = destination
        self.method = method

    @property
    def real_destination(self):
        return os.path.realpath(self.user_destination)

    @property
    def user_destination(self):
        return os.path.expanduser(self.destination)

    @property
    def real_source(self):
        with acquire_repo() as r:
            return os.path.join(r.working_dir, self.source)

    def __repr__(self):
        return "`{} -> {}`".format(self.source, self.destination)

    @property
    def injection_status(self):
        """Verifies if injection is possible, or necessary.

        API wise, return True if """
        if self.method is Method.LINK:
            if self.real_source == self.real_destination:
                return InjectionStatus.AlreadyInjected
            if not os.path.exists(self.real_destination):
                return InjectionStatus.CanInject
            if os.path.exists(self.real_destination):
                return InjectionStatus.InjectionConflict
            else:
                return InjectionStatus.UnkownStatus
        else:
            raise ValueError("{} is not currently a valid injection method".
                             format(self.method.value))

    def inject(self, force=False):
        pass


def _link_injection_method(mappings):
    for mapping in mappings:
        click.secho("Performing mapping: {} ... ".format(mapping), nl=False)
        os.symlink(mapping.real_source, mapping.real_destination)
        click.secho("√", fg='green')


_method_dispatch_dict = {Method.LINK: _link_injection_method}


def injection_method_picker(method):
    _method_func = _method_dispatch_dict.get(method)
    if _method_func is None:
        raise ValueError('Method {} not found'.format(method.value))
    return _method_func
