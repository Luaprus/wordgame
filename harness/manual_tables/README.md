# Manual Annotation Tables

Fill these files instead of editing JSON directly. Column names are Chinese in the CSV/XLSX:

- ideo_events_to_fill.csv
- screenshots_to_fill.csv
- source_index_to_fill.csv

Rules:

1. Keep ID columns unchanged.
2. Fill columns whose names start with ill_.
3. Change status to confirmed only when the row is verified from video, screenshot, source, or manual review.
4. Do not delete rows.
5. If something cannot be confirmed, keep status as manual_required and write the reason in ill_notes.

After the tables are filled, Codex can import them back into the baseline JSON files.
