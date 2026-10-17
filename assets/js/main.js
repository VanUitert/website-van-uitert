/* ==========================================================================
   Van Uitert — site script
   Geen frameworks, geen build-stap: puur vanilla JS zodat het bestand
   direct in de browser draait.
   ========================================================================== */
(function () {
  "use strict";

  /* ---------- mobiel menu ---------- */
  var toggle = document.querySelector(".nav-toggle");
  var nav = document.querySelector(".main-nav");
  if (toggle && nav) {
    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      document.body.style.overflow = open ? "hidden" : "";
    });

    // submenu's uitklappen op mobiel (touch), op desktop gebeurt dit via CSS :hover
    var dropdownParents = document.querySelectorAll("li.has-dropdown > .nav-link");
    dropdownParents.forEach(function (link) {
      link.addEventListener("click", function (e) {
        if (window.innerWidth > 980) return; // desktop: normale link + hover-dropdown
        var parent = link.closest("li");
        var alreadyOpen = parent.classList.contains("is-open");
        if (!alreadyOpen) {
          e.preventDefault();
          document.querySelectorAll("li.has-dropdown.is-open").forEach(function (li) {
            if (li !== parent) li.classList.remove("is-open");
          });
          parent.classList.add("is-open");
        }
      });
    });

    // sluit menu bij navigeren naar een gewoon anker/link op mobiel
    nav.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        if (window.innerWidth <= 980 && !a.closest("li").classList.contains("has-dropdown")) {
          nav.classList.remove("is-open");
          toggle.setAttribute("aria-expanded", "false");
          document.body.style.overflow = "";
        }
      });
    });
  }

  /* ---------- actieve nav-link markeren ---------- */
  var here = location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".main-nav a").forEach(function (a) {
    var href = a.getAttribute("href");
    if (!href) return;
    var file = href.split("/").pop().split("#")[0] || "index.html";
    if (file === here) a.setAttribute("aria-current", "page");
  });

  /* ---------- terug naar boven ---------- */
  var toTop = document.querySelector(".back-to-top");
  if (toTop) {
    window.addEventListener("scroll", function () {
      toTop.classList.toggle("is-visible", window.scrollY > 600);
    });
    toTop.addEventListener("click", function () {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  /* ---------- scroll-reveal ---------- */
  var revealEls = document.querySelectorAll("[data-reveal]");
  if (revealEls.length) {
    if ("IntersectionObserver" in window) {
      var io = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              entry.target.classList.add("is-visible");
              io.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
      );
      revealEls.forEach(function (el) { io.observe(el); });
    } else {
      revealEls.forEach(function (el) { el.classList.add("is-visible"); });
    }
  }

  /* ---------- tellers (stats) ---------- */
  var counters = document.querySelectorAll("[data-count]");
  if (counters.length && "IntersectionObserver" in window) {
    var counted = new WeakSet();
    var cio = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting || counted.has(entry.target)) return;
          counted.add(entry.target);
          animateCount(entry.target);
        });
      },
      { threshold: 0.4 }
    );
    counters.forEach(function (el) { cio.observe(el); });
  } else {
    counters.forEach(function (el) { el.textContent = el.getAttribute("data-count"); });
  }

  function animateCount(el) {
    var target = parseInt(el.getAttribute("data-count"), 10) || 0;
    var duration = 1200;
    var start = null;
    function step(ts) {
      if (start === null) start = ts;
      var progress = Math.min((ts - start) / duration, 1);
      var eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(eased * target);
      if (progress < 1) requestAnimationFrame(step);
      else el.textContent = target;
    }
    requestAnimationFrame(step);
  }

  /* ---------- FAQ accordion ---------- */
  document.querySelectorAll(".faq-item").forEach(function (item) {
    var q = item.querySelector(".faq-q");
    var a = item.querySelector(".faq-a");
    if (!q || !a) return;
    q.addEventListener("click", function () {
      var isOpen = item.classList.contains("is-open");
      item.closest(".faq-list").querySelectorAll(".faq-item.is-open").forEach(function (other) {
        if (other !== item) {
          other.classList.remove("is-open");
          other.querySelector(".faq-a").style.maxHeight = null;
          other.querySelector(".faq-q").setAttribute("aria-expanded", "false");
        }
      });
      item.classList.toggle("is-open", !isOpen);
      q.setAttribute("aria-expanded", !isOpen ? "true" : "false");
      a.style.maxHeight = !isOpen ? a.scrollHeight + "px" : null;
    });
  });

  /* ---------- productfilter (oplossingen-pagina) ---------- */
  var filterBar = document.querySelector("[data-filter-bar]");
  if (filterBar) {
    var chips = filterBar.querySelectorAll(".chip");
    var cards = document.querySelectorAll("[data-tags]");
    var groups = document.querySelectorAll("[data-group]");

    function applyFilter(value) {
      chips.forEach(function (c) {
        c.classList.toggle("is-active", c.getAttribute("data-filter") === value);
        c.setAttribute("aria-pressed", c.getAttribute("data-filter") === value ? "true" : "false");
      });

      if (value === "all") {
        cards.forEach(function (card) { card.classList.remove("is-dimmed"); });
        groups.forEach(function (g) { g.style.display = ""; });
        return;
      }

      cards.forEach(function (card) {
        var tags = (card.getAttribute("data-tags") || "").split(",");
        var match = tags.indexOf(value) !== -1;
        card.classList.toggle("is-dimmed", !match);
      });

      groups.forEach(function (g) {
        var visible = g.querySelectorAll("[data-tags]:not(.is-dimmed)").length;
        g.style.display = visible ? "" : "none";
      });
    }

    chips.forEach(function (chip) {
      chip.addEventListener("click", function () {
        applyFilter(chip.getAttribute("data-filter"));
        history.replaceState(null, "", chip.getAttribute("data-filter") === "all" ? location.pathname : "#" + chip.getAttribute("data-filter"));
      });
    });

    var initial = (location.hash || "").replace("#", "");
    var validInitial = initial && filterBar.querySelector('[data-filter="' + initial + '"]');
    applyFilter(validInitial ? initial : "all");
  }

  /* ---------- contactformulier ---------- */
  document.querySelectorAll("form[data-contact-form]").forEach(function (form) {
    var success = form.parentElement.querySelector(".form-success") || form.querySelector(".form-success");

    // subject vooraf invullen via ?onderwerp=... in de url
    var params = new URLSearchParams(location.search);
    var prefillSubject = params.get("onderwerp");
    if (prefillSubject) {
      var subjectField = form.querySelector('[name="onderwerp"]');
      if (subjectField) {
        var opt = Array.from(subjectField.options || []).find(function (o) {
          return o.value.toLowerCase() === prefillSubject.toLowerCase() || o.textContent.toLowerCase() === prefillSubject.toLowerCase();
        });
        if (opt) subjectField.value = opt.value;
        else if (subjectField.tagName === "INPUT") subjectField.value = prefillSubject;
      }
      var msgField = form.querySelector('[name="bericht"]');
      if (msgField && !msgField.value) {
        msgField.value = "Ik heb een vraag over: " + prefillSubject + "\n\n";
      }
    }

    form.addEventListener("submit", function (e) {
      e.preventDefault();

      // honeypot spamcheck
      var hp = form.querySelector('input[name="website"]');
      if (hp && hp.value) return;

      var valid = true;
      form.querySelectorAll("[required]").forEach(function (field) {
        var wrapper = field.closest(".field");
        var ok = field.type === "checkbox" ? field.checked : field.value.trim() !== "";
        if (field.type === "email" && ok) {
          ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(field.value.trim());
        }
        if (wrapper) wrapper.classList.toggle("has-error", !ok);
        if (!ok) valid = false;
      });

      if (!valid) {
        var firstError = form.querySelector(".has-error input, .has-error select, .has-error textarea");
        if (firstError) firstError.focus();
        return;
      }

      var data = new FormData(form);
      var lines = [
        "Naam: " + (data.get("voornaam") || "") + " " + (data.get("achternaam") || ""),
        "E-mail: " + (data.get("email") || ""),
        "Organisatie: " + (data.get("organisatie") || "-"),
        "Telefoon: " + (data.get("telefoon") || "-"),
        "Onderwerp: " + (data.get("onderwerp") || "-"),
        "",
        (data.get("bericht") || "")
      ];
      var subject = "Contactformulier website — " + (data.get("onderwerp") || "algemene vraag");
      var mailto = "mailto:info@uitert.nl?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(lines.join("\n"));

      if (success) success.classList.add("is-visible");
      form.reset();
      window.location.href = mailto;
    });
  });
})();
