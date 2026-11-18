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
  # foto's: lui laden en per scherm het passende formaat (lijst in assets/img/sizes.txt)
  old='<img src="assets/img/'; new='<img loading="lazy" decoding="async" src="assets/img/'
  body=${body//"$old"/$new}
  old='<img loading="lazy" decoding="async" src="assets/img/logo-'; new='<img src="assets/img/logo-'
  body=${body//"$old"/$new}
  old='<img class="bg" src='; new='<img class="bg" fetchpriority="high" src='
  body=${body//"$old"/$new}
  while read -r n bw sw slot; do
    [ -z "$n" ] && continue
    old="src=\"assets/img/$n.jpg\""
    new="src=\"assets/img/$n.jpg\" srcset=\"assets/img/$n-$sw.jpg ${sw}w, assets/img/$n.jpg ${bw}w\" sizes=\"(max-width:900px) 70vw, $slot\""
    body=${body//"$old"/$new}
  done < assets/img/sizes.txt
  printf '%s\n%s\n%s\n' "$h" "$body" "$foot" > "$out"
done
sed -i -e 's|srcset="assets/|srcset="/assets/|g' -e 's|w, assets/|w, /assets/|g' -e 's|href="assets/|href="/assets/|g' -e 's|src="assets/|src="/assets/|g' -e 's|href="\([a-z-]*\.html\)|href="/\1|g' 404.html
echo "Gebouwd: $(ls src/pages/*.html | wc -l) pagina's"
