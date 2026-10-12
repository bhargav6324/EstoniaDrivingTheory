/**
 * Estonia Driving Theory - Main Application Logic
 * Fast, lightweight, zero external dependencies, accessible, mobile-responsive.
 */
document.addEventListener("DOMContentLoaded", () => {
  // 1. Language Management
  const SUPPORTED_LANGS = ["en", "et", "ru"];
  const DEFAULT_LANG = "en";

  function getInitialLanguage() {
    // 1. Check URL search param (?lang=et)
    const urlParams = new URLSearchParams(window.location.search);
    const urlLang = urlParams.get("lang");
    if (urlLang && SUPPORTED_LANGS.includes(urlLang)) {
      return urlLang;
    }
    // 2. Check localStorage
    try {
      const stored = localStorage.getItem("edt_lang");
      if (stored && SUPPORTED_LANGS.includes(stored)) {
        return stored;
      }
    } catch (e) {
      // localStorage may be disabled in private mode
    }
    // 3. Fallback to default English
    return DEFAULT_LANG;
  }

  let currentLang = getInitialLanguage();

  function applyLanguage(lang) {
    if (!SUPPORTED_LANGS.includes(lang)) lang = DEFAULT_LANG;
    currentLang = lang;
    document.documentElement.lang = lang;
    
    try {
      localStorage.setItem("edt_lang", lang);
    } catch (e) {}

    const dict = (window.TRANSLATIONS && window.TRANSLATIONS[lang]) || window.TRANSLATIONS[DEFAULT_LANG];
    if (!dict) return;

    // Update text elements with data-i18n
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (dict[key] !== undefined) {
        // If it contains HTML entities or breaks, use innerHTML, else textContent
        if (dict[key].includes("<br>") || dict[key].includes("<strong>") || dict[key].includes("<em>")) {
          el.innerHTML = dict[key];
        } else {
          el.textContent = dict[key];
        }
      }
    });

    // Update attribute translations (e.g., data-i18n-attr="aria-label:navFeatures")
    document.querySelectorAll("[data-i18n-attr]").forEach((el) => {
      const raw = el.getAttribute("data-i18n-attr");
      const pairs = raw.split(";");
      pairs.forEach((pair) => {
        const [attr, key] = pair.split(":");
        if (attr && key && dict[key.trim()]) {
          el.setAttribute(attr.trim(), dict[key.trim()]);
        }
      });
    });

    // Update Language Selector Controls
    document.querySelectorAll(".lang-btn").forEach((btn) => {
      const btnLang = btn.getAttribute("data-lang");
      if (btnLang === lang) {
        btn.classList.add("active");
        btn.setAttribute("aria-pressed", "true");
      } else {
        btn.classList.remove("active");
        btn.setAttribute("aria-pressed", "false");
      }
    });

    document.querySelectorAll(".lang-select").forEach((select) => {
      select.value = lang;
    });

    // Fire custom event
    window.dispatchEvent(new CustomEvent("edt_language_changed", { detail: { lang } }));
  }

  // Bind Language Pickers
  document.querySelectorAll(".lang-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const selected = btn.getAttribute("data-lang");
      if (selected) applyLanguage(selected);
    });
  });

  document.querySelectorAll(".lang-select").forEach((select) => {
    select.addEventListener("change", (e) => {
      applyLanguage(e.target.value);
    });
  });

  // 2. Centralized Configuration Binding
  function applyConfig() {
    const config = window.APP_CONFIG || {};

    // Support Email bindings
    if (config.supportEmail) {
      document.querySelectorAll(".support-email-link").forEach((link) => {
        link.href = `mailto:${config.supportEmail}?subject=Estonia%20Driving%20Theory%20Support`;
        link.textContent = config.supportEmail;
      });
      document.querySelectorAll(".support-email-text").forEach((span) => {
        span.textContent = config.supportEmail;
      });
    }

    // App Store Download Buttons
    document.querySelectorAll(".appstore-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        if (!config.isAppStoreLive || !config.appStoreUrl || config.appStoreUrl === "#") {
          e.preventDefault();
          openDownloadModal();
        } else {
          // If valid App Store URL, allow direct navigation
          btn.href = config.appStoreUrl;
          btn.target = "_blank";
          btn.rel = "noopener noreferrer";
        }
      });
    });
  }

  // 3. App Store Download Modal
  const modal = document.getElementById("download-modal");
  const modalCloseBtn = document.getElementById("modal-close-btn");
  const modalBackdrop = document.querySelector(".modal-backdrop");

  function openDownloadModal() {
    if (!modal) return;
    modal.classList.add("active");
    modal.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";
    if (modalCloseBtn) modalCloseBtn.focus();
  }

  function closeDownloadModal() {
    if (!modal) return;
    modal.classList.remove("active");
    modal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
  }

  if (modalCloseBtn) {
    modalCloseBtn.addEventListener("click", closeDownloadModal);
  }
  if (modalBackdrop) {
    modalBackdrop.addEventListener("click", closeDownloadModal);
  }

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && modal && modal.classList.contains("active")) {
      closeDownloadModal();
    }
  });

  // 4. Mobile Navigation Toggle
  const mobileNavToggle = document.getElementById("mobile-nav-toggle");
  const mobileNavDrawer = document.getElementById("mobile-nav-drawer");
  const mobileNavOverlay = document.getElementById("mobile-nav-overlay");

  function toggleMobileNav() {
    if (!mobileNavDrawer) return;
    const isOpen = mobileNavDrawer.classList.toggle("open");
    if (mobileNavToggle) {
      mobileNavToggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
      mobileNavToggle.classList.toggle("active", isOpen);
    }
    if (mobileNavOverlay) {
      mobileNavOverlay.classList.toggle("active", isOpen);
    }
    document.body.style.overflow = isOpen ? "hidden" : "";
  }

  function closeMobileNav() {
    if (mobileNavDrawer && mobileNavDrawer.classList.contains("open")) {
      mobileNavDrawer.classList.remove("open");
      if (mobileNavToggle) {
        mobileNavToggle.setAttribute("aria-expanded", "false");
        mobileNavToggle.classList.remove("active");
      }
      if (mobileNavOverlay) {
        mobileNavOverlay.classList.remove("active");
      }
      document.body.style.overflow = "";
    }
  }

  if (mobileNavToggle) {
    mobileNavToggle.addEventListener("click", toggleMobileNav);
  }
  if (mobileNavOverlay) {
    mobileNavOverlay.addEventListener("click", closeMobileNav);
  }
  document.querySelectorAll(".mobile-nav-link").forEach((link) => {
    link.addEventListener("click", closeMobileNav);
  });

  // 5. FAQ Accordion Logic (Support Page)
  const faqItems = document.querySelectorAll(".faq-item");
  faqItems.forEach((item) => {
    const trigger = item.querySelector(".faq-trigger");
    if (!trigger) return;

    trigger.addEventListener("click", () => {
      const isExpanded = trigger.getAttribute("aria-expanded") === "true";
      // Close other FAQs if desired (or keep independent)
      faqItems.forEach((other) => {
        const otherTrigger = other.querySelector(".faq-trigger");
        if (otherTrigger) {
          otherTrigger.setAttribute("aria-expanded", "false");
          other.classList.remove("active");
        }
      });

      if (!isExpanded) {
        trigger.setAttribute("aria-expanded", "true");
        item.classList.add("active");
      }
    });
  });

  // 6. Road Sign Filter Tabs (Landing Page)
  const signFilterButtons = document.querySelectorAll(".sign-filter-btn");
  const signCards = document.querySelectorAll(".sign-card");

  signFilterButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      signFilterButtons.forEach((b) => {
        b.classList.remove("active");
        b.setAttribute("aria-selected", "false");
      });
      btn.classList.add("active");
      btn.setAttribute("aria-selected", "true");

      const filter = btn.getAttribute("data-category");
      signCards.forEach((card) => {
        const cardCat = card.getAttribute("data-category");
        if (filter === "all" || cardCat === filter) {
          card.style.display = "";
          card.classList.remove("hidden");
        } else {
          card.style.display = "none";
          card.classList.add("hidden");
        }
      });
    });
  });

  // 7. Interactive Exam Simulator Preview Gauge & Question Pill click
  const interactivePills = document.querySelectorAll(".preview-opt-btn");
  interactivePills.forEach((btn) => {
    btn.addEventListener("click", () => {
      const parent = btn.closest(".preview-question-card");
      if (!parent) return;
      parent.querySelectorAll(".preview-opt-btn").forEach((b) => b.classList.remove("selected", "correct", "wrong"));
      
      const isCorrect = btn.getAttribute("data-correct") === "true";
      if (isCorrect) {
        btn.classList.add("correct");
      } else {
        btn.classList.add("wrong");
      }
      
      const explanation = parent.querySelector(".preview-explanation");
      if (explanation) {
        explanation.style.display = "block";
      }
    });
  });

  // Run initialization
  applyConfig();
  applyLanguage(currentLang);
});
