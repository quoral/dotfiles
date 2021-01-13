#!/usr/bin/env python

import iterfzf
import subprocess
from datetime import datetime

class CalendarEvent:
    def __init__(self, event_line):
        # This assumes *a lot*, but should be of the structure
        # start_date, start_time, end_date, end_time, [links], title
        event_details = event_line.split('\t')
        self.title = event_details[-2]
        self.calendar = event_details[-1]
        self.start = datetime.strptime("{} {}".format(event_details[0], event_details[1]), "%Y-%m-%d %H:%M")
        self.meet_links = frozenset(event for event in event_details[4:len(event_details)-2] if event != '' and "meet.google.com" in event)

    def __str__(self):
        return "{}".format(self.title)

    def __repr__(self):
        return "{} {}/{}".format(self.start, self.calendar, self.title)

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


def main():
    agenda_lines = get_todays_agenda()
    agenda_entries = [CalendarEvent(line) for line in agenda_lines if line]
    deduped_agenda = dedupe(agenda_entries)
    deduped_agenda.sort(key=lambda c: c.start, reverse=True)

    agenda_lookup = {repr(entry): entry for entry in deduped_agenda}

    entry = iterfzf.iterfzf(agenda_lookup.keys())
    if entry:
        agenda_entry = agenda_lookup[entry]
        meet_link = (next(iter(agenda_entry.meet_links)))

        subprocess.run(["swaymsg", "exec", "chromium", meet_link])


if __name__ == "__main__":
    main()
