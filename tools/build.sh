#!/usr/bin/env bash
# Bouwt de pagina's: src/pages/*.html + src/partials/* -> *.html in de hoofdmap.
# Een pagina begint met een commentaarblok: title, desc, nav, lang.
# Elke partial is in te voegen met <!--naam--> (naam = bestandsnaam zonder .html).
# Voor lang: nl worden header-nl.html en footer-nl.html gebruikt.
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true
cd "$(dirname "$0")/.."
get(){ sed -n "s/^$1: *//p" "$2" | head -1; }
for f in src/pages/*.html; do
  out=$(basename "$f")
  title=$(get title "$f"); desc=$(get desc "$f"); nav=$(get nav "$f"); lang=$(get lang "$f"); lang=${lang:-en}
  hf=src/partials/header.html; ff=src/partials/footer.html
  [ -f "src/partials/header-$lang.html" ] && hf="src/partials/header-$lang.html"
  [ -f "src/partials/footer-$lang.html" ] && ff="src/partials/footer-$lang.html"
  h=$(cat "$hf"); foot=$(cat "$ff")
  h=${h//'{{TITLE}}'/$title}; h=${h//'{{DESC}}'/$desc}; h=${h//'{{LANG}}'/$lang}
  [ -n "$nav" ] && h=${h//data-nav=\"$nav\"/data-nav=\"$nav\" aria-current=\"page\"}
  body=$(sed '1,/^-->/d' "$f")
  for pass in 1 2; do
    for p in src/partials/*.html; do
      n=$(basename "$p" .html)
      case "$n" in header*|footer*) continue;; esac
      case "$body" in *"<!--$n-->"*) c=$(cat "$p"); body=${body//"<!--$n-->"/$c};; esac
    done
  done
  printf '%s\n%s\n%s\n' "$h" "$body" "$foot" > "$out"
done
sed -i -e 's|href="assets/|href="/assets/|g' -e 's|src="assets/|src="/assets/|g' -e 's|href="\([a-z-]*\.html\)|href="/\1|g' 404.html
echo "Gebouwd: $(ls src/pages/*.html | wc -l) pagina's"
