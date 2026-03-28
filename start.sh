#!/bin/bash
# Start the slideshow web server and open it in a browser.
# Run from the repo root.

cd "$(dirname "$0")/docs"
PORT=8765
URL="http://localhost:${PORT}/recordings/"

echo "Slideshow: $URL"
echo "Press Ctrl+C to stop."
echo

xdg-open "$URL" 2>/dev/null || open "$URL" 2>/dev/null || echo "(open $URL in your browser)"

exec python3 -m http.server "$PORT"
