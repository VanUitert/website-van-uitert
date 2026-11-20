#!/usr/bin/env bash
# Bouwt de pagina's: src/pages/*.html + src/partials/* -> *.html in de hoofdmap.
# Een pagina begint met een commentaarblok: title, desc, nav, lang.
# Elke partial is in te voegen met <!--naam--> (naam = bestandsnaam zonder .html).
# Voor lang: nl worden header-nl.html en footer-nl.html gebruikt.
set -euo pipefail
shopt -u patsub_replacement 2>/dev/null || true
cd "$(dirname "$0")/.."
# Bestand in een variabele lezen zonder extra proces: op Windows kost elk los proces tijd,
# daarom staat hier geen cat, sed of basename in de lus (bouwen ging van een minuut naar seconden).
lees(){ local -n _v=$1; IFS= read -r -d '' _v < "$2" || true; while [[ $_v == *$'\n' ]]; do _v=${_v%$'\n'}; done; }
waarde(){ local -n _w=$1; _w=${2#*:}; _w=${_w#"${_w%%[! ]*}"}; }
declare -A P; namen=()
for p in src/partials/*.html; do
  n=${p##*/}; n=${n%.html}; lees c "$p"; P[$n]=$c
  case "$n" in header*|footer*) ;; *) namen+=("$n");; esac
done
aantal=0
for f in src/pages/*.html; do
  out=${f##*/}; lees alles "$f"
  title=; desc=; nav=; lang=; t=0; d=0; v=0; g=0
  while IFS= read -r r; do
    case "$r" in
      'title:'*) if [ $t = 0 ]; then waarde title "$r"; t=1; fi;;
      'desc:'*)  if [ $d = 0 ]; then waarde desc "$r"; d=1; fi;;
      'nav:'*)   if [ $v = 0 ]; then waarde nav "$r"; v=1; fi;;
      'lang:'*)  if [ $g = 0 ]; then waarde lang "$r"; g=1; fi;;
      '-->'*) break;;
    esac
  done <<< "$alles"
  lang=${lang:-en}
  hn=header; fn=footer
  if [ -n "${P[header-$lang]+x}" ]; then hn="header-$lang"; fi
  if [ -n "${P[footer-$lang]+x}" ]; then fn="footer-$lang"; fi
  h=${P[$hn]}; foot=${P[$fn]}
  h=${h//'{{TITLE}}'/$title}; h=${h//'{{DESC}}'/$desc}; h=${h//'{{LANG}}'/$lang}
  [ -n "$nav" ] && h=${h//data-nav=\"$nav\"/data-nav=\"$nav\" aria-current=\"page\"}
  body=${alles#*$'\n-->'}; body=${body#*$'\n'}
  for pass in 1 2; do
    for n in "${namen[@]}"; do
      case "$body" in *"<!--$n-->"*) c=${P[$n]}; body=${body//"<!--$n-->"/$c};; esac
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
    slot=${slot%$'\r'}; [ -z "$n" ] && continue
    old="src=\"assets/img/$n.jpg\""
    new="src=\"assets/img/$n.jpg\" srcset=\"assets/img/$n-$sw.jpg ${sw}w, assets/img/$n.jpg ${bw}w\" sizes=\"(max-width:900px) 70vw, $slot\""
    body=${body//"$old"/$new}
  done < assets/img/sizes.txt
  printf '%s\n%s\n%s\n' "$h" "$body" "$foot" > "$out"
  aantal=$((aantal + 1))
done
sed -i -e 's|srcset="assets/|srcset="/assets/|g' -e 's|w, assets/|w, /assets/|g' -e 's|href="assets/|href="/assets/|g' -e 's|src="assets/|src="/assets/|g' -e 's|href="\([a-z-]*\.html\)|href="/\1|g' 404.html
echo "Gebouwd: $aantal pagina's"
