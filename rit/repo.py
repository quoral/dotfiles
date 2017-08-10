from git import Repo
from contextlib import contextmanager
from threading import RLock


__repo = Repo(__file__, search_parent_directories=True)
__repo_lock = RLock()


@contextmanager
def acquire_repo():
    with __repo_lock:
        yield __repo
