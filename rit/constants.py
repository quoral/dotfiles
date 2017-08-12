from enum import Enum


class Method(Enum):
    COPY = 'copy'
    LINK = 'link'


DEFAULT_METHOD = Method.COPY
Methods = [m.value for m in Method]

MAP_FILENAME = "mappings.json"
MAP_LOCATION = MAP_FILENAME
