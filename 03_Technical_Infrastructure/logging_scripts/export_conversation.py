#!/usr/bin/env python3
# Exports chat logs to markdown with timestamps

import datetime, os, sys
fn = f"Session_{datetime.date.today().isoformat()}.md"
with open(fn, "w", encoding="utf-8") as f:
    f.write("# Conversation Log\n\n")
    f.write(f"Date: {datetime.datetime.now()}\n\n---\n")
print(f"Exported {fn}")
