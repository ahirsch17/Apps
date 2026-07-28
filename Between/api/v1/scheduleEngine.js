/**
 * Campus schedule overlap engine — mirrors iOS ScheduleEngine.swift
 */

const DAY_MAP = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };

const START_MINUTES = 8 * 60;
const END_MINUTES = 18 * 60;
const MIN_FREE_BLOCK = 30;
const MIN_OVERLAP = 25;
const MAX_EMPTY_FREE = 90;

const DEMO_WEEKDAY = 3; // Wednesday
const DEMO_NOW = 10 * 60 + 15;

function minutesFromTime(time) {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
}

function formatTime12Hour(minutes) {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  const h12 = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
  const ampm = hours < 12 ? 'AM' : 'PM';
  if (mins === 0) return `${h12} ${ampm}`;
  return `${h12}:${String(mins).padStart(2, '0')} ${ampm}`;
}

function formatRange(start, end) {
  return `${formatTime12Hour(start)} – ${formatTime12Hour(end)}`;
}

function sectionsForDay(dayIdx, sections) {
  return sections.filter((s) => s.meetingDays.some((d) => DAY_MAP[d] === dayIdx));
}

function busyIntervals(dayIdx, sections) {
  return sectionsForDay(dayIdx, sections)
    .map((section) => {
      const start = minutesFromTime(section.startTime);
      const end = minutesFromTime(section.endTime);
      const clampedStart = Math.max(start, START_MINUTES);
      const clampedEnd = Math.min(end, END_MINUTES);
      if (clampedEnd <= clampedStart) return null;
      return { start: clampedStart, end: clampedEnd, section };
    })
    .filter(Boolean)
    .sort((a, b) => a.start - b.start);
}

function freeIntervals(dayIdx, sections) {
  const busy = busyIntervals(dayIdx, sections).map(({ start, end }) => ({ start, end }));
  const free = [];
  let prev = START_MINUTES;
  for (const b of busy) {
    if (b.start > prev) free.push({ start: prev, end: b.start });
    prev = Math.max(prev, b.end);
  }
  if (prev < END_MINUTES) free.push({ start: prev, end: END_MINUTES });
  return free;
}

function intersectIntervals(a, b) {
  const result = [];
  const sa = [...a].sort((x, y) => x.start - y.start);
  const sb = [...b].sort((x, y) => x.start - y.start);
  let i = 0;
  let j = 0;
  while (i < sa.length && j < sb.length) {
    const start = Math.max(sa[i].start, sb[j].start);
    const end = Math.min(sa[i].end, sb[j].end);
    if (end > start) result.push({ start, end });
    if (sa[i].end < sb[j].end) i++;
    else j++;
  }
  return result;
}

function clipOverlaps(overlaps, nowMinutes) {
  return overlaps
    .map((o) => {
      const intervals = o.intervals
        .map(({ start, end }) => {
          const s = Math.max(start, nowMinutes);
          return end > s && end - s >= MIN_OVERLAP ? { start: s, end } : null;
        })
        .filter(Boolean);
      if (!intervals.length) return null;
      const total = intervals.reduce((sum, iv) => sum + (iv.end - iv.start), 0);
      return { ...o, intervals, totalMinutes: total };
    })
    .filter(Boolean);
}

function appendIfFuture(item, nowMinutes, timeline) {
  if (item.endMinutes <= nowMinutes) return;
  if (item.startMinutes < nowMinutes) {
    timeline.push({
      ...item,
      startMinutes: nowMinutes,
      friendOverlaps: clipOverlaps(item.friendOverlaps, nowMinutes),
    });
  } else {
    timeline.push(item);
  }
}

function friendOverlaps(start, end, dayIdx, friendSectionsById, friendNamesById) {
  const userFree = [{ start, end }];
  const overlaps = [];
  for (const [friendId, sections] of Object.entries(friendSectionsById)) {
    const friendFree = freeIntervals(dayIdx, sections);
    const intervals = intersectIntervals(userFree, friendFree).filter(
      (iv) => iv.end - iv.start >= MIN_OVERLAP
    );
    if (!intervals.length) continue;
    const totalMinutes = intervals.reduce((s, iv) => s + (iv.end - iv.start), 0);
    overlaps.push({
      id: `${friendId}-${start}`,
      friendId,
      friendName: friendNamesById[friendId] || 'Friend',
      intervals,
      totalMinutes,
    });
  }
  return overlaps.sort((a, b) => b.totalMinutes - a.totalMinutes || a.friendName.localeCompare(b.friendName));
}

function buildTodayPlan(mySections, friendSectionsById, friendNamesById) {
  const dayIdx = DEMO_WEEKDAY;
  const nowMinutes = DEMO_NOW;
  const free = freeIntervals(dayIdx, mySections);
  const busy = busyIntervals(dayIdx, mySections);
  const timeline = [];
  let fi = 0;
  let bi = 0;

  while (fi < free.length || bi < busy.length) {
    const nf = fi < free.length ? free[fi] : null;
    const nb = bi < busy.length ? busy[bi] : null;
    if (!nf && !nb) break;

    if (nf && (!nb || nf.start <= nb.start)) {
      const overlaps = friendOverlaps(nf.start, nf.end, dayIdx, friendSectionsById, friendNamesById);
      if (!overlaps.length) {
        const duration = nf.end - nf.start;
        if (duration >= MIN_FREE_BLOCK && duration <= MAX_EMPTY_FREE) {
          appendIfFuture(
            {
              id: `free-${nf.start}-${nf.end}`,
              kind: 'freeBlock',
              startMinutes: nf.start,
              endMinutes: nf.end,
              section: null,
              friendOverlaps: [],
            },
            nowMinutes,
            timeline
          );
        }
      } else {
        for (const overlap of overlaps) {
          const best = overlap.intervals
            .filter((iv) => iv.end - iv.start >= MIN_OVERLAP)
            .sort((a, b) => b.end - b.start - (a.end - a.start))[0];
          if (!best) continue;
          appendIfFuture(
            {
              id: `overlap-${overlap.friendId}-${best.start}`,
              kind: 'freeBlock',
              startMinutes: best.start,
              endMinutes: best.end,
              section: null,
              friendOverlaps: [
                {
                  id: `${overlap.friendId}-${best.start}`,
                  friendId: overlap.friendId,
                  friendName: overlap.friendName,
                  intervals: [best],
                  totalMinutes: best.end - best.start,
                },
              ],
            },
            nowMinutes,
            timeline
          );
        }
      }
      fi++;
    } else if (nb) {
      appendIfFuture(
        {
          id: `class-${nb.section.sectionId}`,
          kind: 'classBlock',
          startMinutes: nb.start,
          endMinutes: nb.end,
          section: nb.section,
          friendOverlaps: [],
        },
        nowMinutes,
        timeline
      );
      bi++;
    }
  }

  return timeline.sort((a, b) => a.startMinutes - b.startMinutes);
}

function serializeTodayPlan(items) {
  return items.map((item) => ({
    id: item.id,
    kind: item.kind,
    startMinutes: item.startMinutes,
    endMinutes: item.endMinutes,
    section: item.section,
    friendOverlaps: item.friendOverlaps.map((o) => ({
      id: o.id,
      friendId: o.friendId,
      friendName: o.friendName,
      intervals: o.intervals.map((iv) => [iv.start, iv.end]),
      totalMinutes: o.totalMinutes,
    })),
  }));
}

module.exports = {
  buildTodayPlan,
  serializeTodayPlan,
  formatRange,
  formatTime12Hour,
  DEMO_WEEKDAY,
};
