import os
from enum import Enum, auto

from rit.constants import Method
from rit.repo import acquire_repo


class InjectionStatus(Enum):
    AlreadyInjected = auto()
    CanInject = auto()
    InjectionConflict = auto()
    UnkownStatus = auto()


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

    def verify_injection(self):
        """Verifies if injection is possible, or necessary.

        API wise, return True if """
        if self.method is Method.LINK:
            if self.real_source == self.real_destination:
                return InjectionStatus.AlreadyInjected
            if not os.path.exists(self.destination):
                return InjectionStatus.CanInject
            if os.path.exists(self.destination):
                return InjectionStatus.InjectionConflict
            else:
                return InjectionStatus.UnkownStatus
        else:
            raise ValueError("{} is not currently a valid injection mapping".
                             format(self.mapping.value))

    def inject(self, force=False):
        pass
