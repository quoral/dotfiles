#!/usr/bin/env python3

import psutil
import re
import pulsectl
import warnings

from emoji import emojize
from pathlib import Path
from datetime import datetime, timedelta


IGNORED_INTERFACE_PATTERNS = ["lo", "docker.*"]
BASE_NET_PATH = "/sys/class/net"
def decorate_interface(iff, stats):
    wireless_folder_path = Path(BASE_NET_PATH, iff, "wireless")
    interface_is_wireless = wireless_folder_path.is_dir()
    return {
        "stats": stats,
        "is_up": stats.isup,
        "is_wireless": interface_is_wireless
    }

def mean(seq):
    return sum(seq)/len(seq)

def to_pct(num):
    return num*100

def get_interfaces():
    interfaces = set()
    for iff in psutil.net_if_addrs().keys():
        if not any(re.match(ignore_pattern, iff) for ignore_pattern in IGNORED_INTERFACE_PATTERNS):
            interfaces.add(iff)

    iff_stats = {
        iff: decorate_interface(iff, stats)
        for iff, stats
        in psutil.net_if_stats().items()
        if iff in interfaces
    }

    return iff_stats

def pulse_output(pulse_client):
    default_sink_name = pulse_client.server_info().default_sink_name
    default_sink = next(sink for sink in pulse_client.sink_list() if sink.name == default_sink_name)

    mean_pct = mean(default_sink.volume.values)
    percentage_string = "{}%".format(round(to_pct(mean_pct)))

    form_factor = default_sink.proplist["device.form_factor"]
    is_muted = default_sink.mute == 1

    pulse_string = ""
    if is_muted:
        pulse_string += ":mute:"
        return pulse_string
    if form_factor == "headphone":
        pulse_string += ":headphones:"
    else:
        pulse_string += ":speaker:"

    pulse_string += percentage_string

    return pulse_string

  
def date_output(date):
    return date.strftime("%Y-%m-%d %H:%M:%S")

def battery_output(battery):
    if battery.percent > 80:
        percentage_string = ":green_heart:"
    elif battery.percent > 30:
        percentage_string = ":orange_heart:"
    else:
        percentage_string = ":red_heart:"

    minutes_left = battery.secsleft // 60
    if minutes_left < 0:
        minutes_string = ""
    else:
        minutes_string = "{}m".format(minutes_left)

    if battery.power_plugged:
        battery_string = ":electric_plug: {}".format(percentage_string)
    else:
        battery_string = ":battery: {} {}".format(percentage_string, minutes_string)

    return battery_string

def network_output():
    interfaces = get_interfaces()
    network_string = ""
    for interface, info in interfaces.items():
        interface_string = ""
        if not info["is_up"]:
            continue
        if info["is_wireless"]:
            interface_string += ":signal_strength:"
        else:
            interface_string += ":globe_with_meridians:"
        if info["is_up"]:
            interface_string += ":green_heart:"
        else:
            interface_string += ":red_heart:"
        network_string += interface_string
    return network_string

def load_output():
    load_avg = psutil.getloadavg()
    return ":suspension_railway: {}".format(" ".join(str(load) for load in load_avg))

def memory_output():
    virtual_memory = psutil.virtual_memory()
    return ":ram: {}%".format(virtual_memory.percent)

def compose_output():
    date_string = date_output(datetime.now())
    battery_string = battery_output(psutil.sensors_battery())
    network_string = network_output()
    with pulsectl.Pulse('sway-bar-client') as pulse_client:
        audio_string = pulse_output(pulse_client)
    load_string = load_output()
    memory_string = memory_output()

    return emojize("{}  {}  {}  {}  {}  {}".format(load_string, memory_string, audio_string, battery_string, network_string, date_string), use_aliases=True)

print(compose_output())
