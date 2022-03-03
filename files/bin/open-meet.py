#!/usr/bin/env python

import iterfzf
import subprocess
import click
from datetime import datetime

class CalendarEvent:
    def __init__(self, event_line):
        # This assumes *a lot*, but should be of the structure
        # start_date, start_time, end_date, end_time, [links], title
        event_details = event_line.split('\t')
        self.title = event_details[-2]
        self.calendar = event_details[-1]
        self.start = datetime.strptime("{} {}".format(event_details[0], event_details[1]), "%Y-%m-%d %H:%M")
        print(event_details)
        self.meet_links = frozenset(event for event in event_details[4:len(event_details)-2] if event != '' and "meet.google.com" in event)

    def __str__(self):
        return "{}".format(self.title)

    def __repr__(self):
        start_time_string = self.start.strftime("%H:%M")
        return "{} {}/{}".format(start_time_string, self.calendar, self.title)

def get_todays_agenda():
    result = subprocess.run(["gcalcli", "agenda", "today", "tonight", "--tsv", "--details=url", "--details=calendar"], stdout=subprocess.PIPE)
    result_lines = result.stdout.decode('utf-8').split("\n")
    return result_lines

def dedupe(agenda_entries):
    agenda_dict = dict()
    for entry in agenda_entries:
        set_key = entry.meet_links.union(frozenset([entry.title]))
        if entry.meet_links in agenda_dict:
            agenda_dict[set_key].append(entry)
            continue
        agenda_dict[set_key] = [entry]
    return [(entry_list[0]) for entry_list in agenda_dict.values()]

def fzf_picker(items):
    return iterfzf.iterfz(items)

def menu_picker(items):
    item_list = list(items)
    item_list.reverse()
    item_input = "\n".join(item_list)
    process = subprocess.run(["wofi", "-i", "-d", "--cache-file=/dev/null", "--sort-order=default", "--columns=2"], input=item_input, encoding="utf-8", stdout=subprocess.PIPE)
    return process.stdout.strip()


@click.command()
@click.option('--picker', default="wofi", type=click.Choice(['wofi', "fzf"], case_sensitive=False))
def main(picker):
    agenda_lines = get_todays_agenda()
    agenda_entries = [CalendarEvent(line) for line in agenda_lines if line]
    deduped_agenda = dedupe(agenda_entries)
    deduped_agenda.sort(key=lambda c: c.start, reverse=True)

    agenda_lookup = {repr(entry): entry for entry in deduped_agenda if len(entry.meet_links) > 0}

    if picker == "fzf":
        entry = fzf_picker(agenda_lookup.keys())
    elif picker == "wofi":
        entry = menu_picker(agenda_lookup.keys())

    if entry:
        agenda_entry = agenda_lookup[entry]
        try:
            meet_link = (next(iter(agenda_entry.meet_links)))
            subprocess.run(["swaymsg", "exec", "chromium", meet_link])
        except (StopIteration):
            print("No meet link found")



if __name__ == "__main__":
    main()
