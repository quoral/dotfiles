#!/usr/bin/env python3

from iterfzf import iterfzf
import subprocess
import json
import sys
from subprocess import run

def op_command(command):
    inner_command = ["op"] + command
    result = run(inner_command, check=True,
                stdout=subprocess.PIPE,
                )

    return json.loads(result.stdout)

def get_password(item):
    details = item["details"]
    if "password" in details and details["password"]:
        return details["password"]
    password_field = next(field for field in details["fields"] if field["type"] == "P")
    return password_field["value"]

items = op_command(["list", "items"])
titles = {item["overview"]["title"]: item for item in items}

selected = iterfzf(titles.keys())

item_info = op_command(["get", "item", titles[selected]["uuid"]])

password = get_password(item_info)
print(password.rstrip('\r\n'), end='')