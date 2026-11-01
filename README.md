# L51 – Mood Journal

**Student:** HIMANI GOHEL | **Roll:** E11 | **Division:** H

## Problem

Create a daily journal with a mood score and weekly mood stats.

## Who will use it

Anyone who wants to track mood over the semester.

## Folder Structure

* main.sh – Menu and program execution
* lib/functions.sh – All project functions
* data/ – Journal data files
* reports/ – Generated reports
* backups/ – TAR.GZ backups
* logs/ – Activity and cron logs

## Features

1. Write today's entry with mood 1–5
2. Weekly mood average
3. Best and worst days
4. Search entries by word
5. Word count per entry

## How to Run

```
cd ~/linux_project/moodjournal
./main.sh
./main.sh --help
```

## Crontab Task

Every day at 9 PM, append a journal reminder. Every Sunday, generate a weekly mood report.

```
0 21 * * * /bin/bash $HOME/linux_project/moodjournal/main.sh --cron >> $HOME/linux_project/moodjournal/logs/cron.log 2>&1
```

## Commands Used

date, awk, grep, wc, ls, sed, tar, mkdir

## What I Learned

* Learned Bash scripting and Linux commands.
* Learned loops, conditions and functions.
* Learned file handling and input validation.
* Learned to calculate weekly mood statistics.
* Learned to create backups and schedule tasks using cron.

## Project Guide

This project was completed under the guidance of
**Dr. Anjum Y. Mansuri**, Assistant Professor, Computer Applications,
LJ Institute of Computer Applications, LJ University, Ahmedabad.

GitHub: [@anjum-mansuri](https://github.com/anjum-mansuri)

## Course Details

* Course: OS Linux Lab 260120510
* Project ID: L51
* Project Name: Mood Journal

