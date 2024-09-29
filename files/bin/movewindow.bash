#!/bin/bash

mapfile -t SortedMonitors <<< "$(hyprctl monitors -j | jq -r 'sort_by(.x) | .[] | .id')"
# SortedMonitors=(2 0 1)
CurrentMonitor="$(hyprctl activeworkspace -j | jq ".monitorID")"
Direction="$1"
SortedMonitorsSize="${#SortedMonitors[@]}"

declare CurrentIndex

# find the index of the current monitor in the sorted monitors array
for index in "${!SortedMonitors[@]}"; do
    if [[ "${SortedMonitors[$index]}" == "$CurrentMonitor" ]]; then
        CurrentIndex="$index"
        break
    fi
done

if [[ $Direction == "r" ]]; then
    ((CurrentIndex++))
elif [[ $Direction == "l" ]]; then
    ((CurrentIndex--))
fi

# Loopback logic
if (( CurrentIndex == SortedMonitorsSize )); then
    CurrentIndex=0
elif (( CurrentIndex < 0 )); then
    CurrentIndex=$((SortedMonitorsSize - 1))
fi

NextMonitorId="${SortedMonitors[$CurrentIndex]}"

hyprctl dispatch movewindow mon:"$NextMonitorId"
