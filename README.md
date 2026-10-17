# Van Uitert — website (concept)

Nieuwe website voor Van Uitert B.V., gebaseerd op uitert.nl. Pure HTML/CSS/JavaScript:
geen database, geen build-stap, geen server-code. Elke statische host kan hem draaien.

## Bekijken op je eigen pc

Dubbelklik op `index.html`. Klaar.

## Structuur

```
index.html                           Home
oplossingen.html                     Alle oplossingen, met productfilter
oplossingen-qimarox-palletiser.html  Voorbeeld-detailpagina (template voor de rest)
diensten.html                        Engineering, lijnaudit, inspecties, onderhoud, spare parts
over-ons.html                        Geschiedenis, team, klanten
werken-bij.html                      Werken bij / open sollicitatie
contact.html                         Contactformulier, adres, kaart
404.html                             Foutpagina bij een onbekende URL
robots.txt                           Zoekmachine-instelling (staat nu op "niet indexeren")
assets/css/style.css                 Alle opmaak; kleuren staan bovenin als variabelen
assets/js/main.js                    Menu, filter, FAQ, formulier
assets/img/                          Logo, foto's, klantlogo's
```

Header en footer staan in elke pagina los. Pas je een menu-item aan, doe dat dan in alle
`.html`-bestanden.

## Publiceren via GitHub Pages

1. Zet de wijzigingen in de repository (`git add -A`, `git commit -m "..."`, `git push`).
2. GitHub > repository > **Settings > Pages** > Source: *Deploy from a branch*,
   branch `main`, map `/ (root)`.
3. Na een minuut staat de site op `https://<account>.github.io/<repository>/`.
   Elke volgende `git push` werkt de site automatisch bij.

## Checklist vóór echte livegang

- [ ] `robots.txt` omzetten naar `Allow: /` (staat nu bewust dicht in de conceptfase)
- [ ] Eigen domein koppelen (Settings > Pages > Custom domain) en DNS bij de provider aanpassen
- [ ] Contactformulier aan een echte verwerker koppelen (bijv. Formspree); nu opent het
      het mailprogramma van de bezoeker (`mailto:`)
- [ ] Privacybeleid, cookieverklaring, disclaimer en algemene voorwaarden toevoegen en
      linken vanuit footer en formulier
- [ ] Detailpagina's voor de overige oplossingen maken (kopie van de Qimarox-pagina)
- [ ] `sitemap.xml` toevoegen zodra het definitieve domein vaststaat
