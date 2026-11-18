# Van Uitert website (concept)

Nieuwe website voor Van Uitert B.V. Positionering: lijnintegrator. Ontwerp: "De rode draad".
Statische site: HTML, CSS en een klein script. Geen database, geen WordPress, geen vast thema.

## Pagina's

| Pagina | Bestand | Doel |
|---|---|---|
| Home | `index.html` | Boodschap en klantlogo's in het eerste scherm, drie vragen, de lijn met zes stations, cijfers, projecten |
| What we do | `solutions.html` | Overzicht: drie oplossingen en service |
| Oplossing | `new-line.html`, `line-upgrade.html`, `line-relocation.html` | Eigen pagina per oplossing, vindbaar in Google |
| Machines | `machines.html` | Overzicht met zes kaarten (03 = machine van een ander merk) |
| Machine | `depalletisers.html`, `rinsers-dryers.html`, `conveyors.html`, `robot-packers.html`, `palletisers.html` | Uitvoeringen met capaciteit, producten en opties |
| Projects | `projects.html` | Overzicht van projecten met filter op branche |
| Project | `project-heineken-zoeterwoude.html`, `project-abbott-zwolle.html`, `project-abinbev-hoegaarden.html` | Proefpagina's, tekst en cijfers nog te bevestigen |
| About us | `about.html` | Bedrijf, geschiedenis, partners |
| Werken bij | `werken-bij.html` | Vacatures met details en sollicitatieformulier (Nederlands, eigen kop en voet) |
| Contact | `contact.html` | Formulier bovenaan, bijlage mogelijk, contactpersonen |

## Vaste regels van het ontwerp

- Een idee: de rode draad loopt over elke pagina en eindigt bij een persoon.
- Vier menu-items en een knop: "Start your project".
- Elke pagina eindigt met hetzelfde slotblok. Oplossings- en machinepagina's tonen daarboven een passend project.
- Cijfers alleen uit eigen bronnen: leaflets en materiaalbladen op `L:PB.0 Machinebeschrijvingen`, de huidige site of een orderdocument. Geen foto bij een machine of project waar hij niet bij hoort.
- Kleuren: rood, antraciet, wit. Geen mobiele nummers. Quotes alleen met functie en bedrijf.

## Aanpassen

| Wat | Waar |
|---|---|
| Tekst van een pagina | `src/pages/<pagina>.html` |
| Menu, kop, voet | `src/partials/header.html` en `footer.html`; voor Werken bij `header-nl.html` en `footer-nl.html` |
| Slotblok met contactpersonen | `src/partials/closing.html` |
| Projectkaart per project | `src/partials/card-<project>.html` (gebruikt op home, Projects en als passend project) |
| Passend project onder een pagina | regel `<!--rel-heineken-->`, `<!--rel-abbott-->` of `<!--rel-abinbev-->` in de pagina |
| Vacatures | `src/partials/jobs-nl.html` en de keuzelijst in `src/pages/werken-bij.html` |
| Voorkeuze in het contactformulier | link naar `contact.html?about=Line%20audit` (tekst moet gelijk zijn aan een keuze) |
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
- [ ] Formulieren `project` en `sollicitatie`: Netlify Forms aanzetten met melding naar info@uitert.nl (tot dan opent het formulier het mailprogramma en gaat een bijlage niet mee)
- [ ] Serviceadres bevestigen (nu services@uitert.nl; in het adresboek staat services@uitert.com en spares@uitert.nl)
- [ ] Projectpagina's: toestemming klant voor naam, tekst, foto en quote op de website
- [ ] Foto's per machine-uitvoering uit de beeldbank aanvullen
- [ ] Lettertypen zelf hosten in plaats van via Google
- [ ] Privacy, cookies en algemene voorwaarden
- [ ] `robots.txt` op `Allow: /` en `noindex` uit de kop halen
- [ ] Domein uitert.nl koppelen, `sitemap.xml` toevoegen
- [ ] Het label CONCEPT linksonder weghalen
