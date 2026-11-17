#!/usr/bin/env bash
# Bouwt de pagina's van de website.
#   src/pages/*.html    inhoud per pagina; bovenaan staan titel, omschrijving, menu-item en taal
#   src/partials/       kop, slotblok en voet: een keer aanpassen geldt voor alle pagina's
# Gebruik:  bash tools/build.sh   (vanuit de hoofdmap van de website)
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true
cd "$(dirname "$0")/.."
head=$(cat src/partials/header.html)
closing=$(cat src/partials/closing.html)
foot=$(cat src/partials/footer.html)
cases=$(cat src/partials/cases.html)
get(){ sed -n "s/^$1: *//p" "$2" | head -1; }
for f in src/pages/*.html; do
  out=$(basename "$f")
  title=$(get title "$f"); desc=$(get desc "$f"); nav=$(get nav "$f"); lang=$(get lang "$f")
  h=${head//'{{TITLE}}'/$title}; h=${h//'{{DESC}}'/$desc}; h=${h//'{{LANG}}'/${lang:-en}}
  [ -n "$nav" ] && h=${h//data-nav=\"$nav\"/data-nav=\"$nav\" aria-current=\"page\"}
  body=$(sed '1,/^-->/d' "$f")
  body=${body//'<!--closing-->'/$closing}; body=${body//'<!--cases-->'/$cases}
  printf '%s\n%s\n%s\n' "$h" "$body" "$foot" > "$out"
  echo "gebouwd: $out"
done
# De foutpagina wordt op elk adres getoond: daar moeten de verwijzingen vanaf de hoofdmap lopen.
sed -i -e 's|href="assets/|href="/assets/|g' -e 's|src="assets/|src="/assets/|g' -e 's|href="\([a-z-]*\.html\)|href="/\1|g' 404.html
