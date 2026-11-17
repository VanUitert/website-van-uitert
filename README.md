# Van Uitert website (concept)

Nieuwe website voor Van Uitert B.V. Positionering: lijnintegrator. Ontwerp: "De rode draad".
Statische site: HTML, CSS en een klein script. Geen database, geen WordPress, geen vast thema.

## Pagina's

| Pagina | Bestand | Doel |
|---|---|---|
| Home | `index.html` | Boodschap, drie vragen, de lijn met zes stations, bewijs, projecten |
| What we do | `solutions.html` | Nieuwe lijn, lijn verbeteren, lijn verhuizen, service |
| Machines | `machines.html` | Wat we zelf bouwen, per station |
| Projects | `projects.html` | Overzicht van cases (proefpagina's) |
| Case | `project-heineken-zoeterwoude.html` | Proefpagina voor een case |
| About us | `about.html` | Bedrijf, geschiedenis, partners |
| Werken bij | `werken-bij.html` | Vacatures (Nederlands) |
| Contact | `contact.html` | Formulier en contactpersonen |

## Vaste regels van het ontwerp

- Een idee: de rode draad loopt over elke pagina en eindigt bij een persoon.
- Vier menu-items en een knop: "Start your project".
- Elke pagina eindigt met hetzelfde slotblok.
- Kleuren: rood, antraciet, wit. Geen mobiele nummers. Quotes alleen met functie en bedrijf.

## Aanpassen

| Wat | Waar |
|---|---|
| Tekst van een pagina | `src/pages/<pagina>.html` |
| Menu, kop, voet | `src/partials/header.html` en `footer.html` |
| Slotblok met contactpersonen | `src/partials/closing.html` |
| Projectkaarten (home en Projects) | `src/partials/cases.html` |
| Opmaak | `assets/css/site.css` |
| Gedrag (rode draad, stations, formulier) | `assets/js/site.js` |

Na een wijziging in `src/`: pagina's opnieuw bouwen.

```
bash tools/build.sh
```

## Bekijken op de eigen pc

```
powershell -ExecutionPolicy Bypass -File tools\serve.ps1
```

Daarna in de browser: http://localhost:8377/

## Online zetten

`git add -A`, `git commit`, `git push`. Netlify zet de nieuwe versie vanzelf online.
De eerste versie (marineblauw) staat in git onder het label `v1-marineblauw`.

## Checklist voor livegang

- [ ] Proefpagina's van de cases vullen en laten goedkeuren
- [ ] Nederlandse versie onder `/nl/`
- [ ] Beheeromgeving voor vacatures (HR zet zelf online en offline)
- [ ] Formulier: Netlify Forms aanzetten (tot dan opent het formulier het mailprogramma)
- [ ] Mailadres voor sollicitaties bevestigen (nu info@uitert.nl)
- [ ] Lettertypen zelf hosten in plaats van via Google
- [ ] Privacy, cookies en algemene voorwaarden
- [ ] `robots.txt` op `Allow: /` en `noindex` uit de kop halen
- [ ] Domein uitert.nl koppelen, `sitemap.xml` toevoegen
- [ ] Het label CONCEPT linksonder weghalen
