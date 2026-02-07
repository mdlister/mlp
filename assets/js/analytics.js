(() => {
  if (typeof gtag === 'undefined') return;

  const seenSections = new Set();

  const pageType = document.documentElement.dataset.pageType ||
                   document.querySelector('meta[name="page_type"]')?.content ||
                   'unknown';

  const sections = Array.from(document.querySelectorAll('section[id]'));

  // ----------------------------------------
  // SECTION VIEW TRACKING
  // ----------------------------------------
  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;

      const section = entry.target;
      const sectionId = section.id;

      if (seenSections.has(sectionId)) return;
      seenSections.add(sectionId);

      const sectionOrder = sections.indexOf(section) + 1;

      gtag('event', 'section_viewed', {
        section_id: sectionId,
        section_order: sectionOrder,
        page_type: pageType,
        page_path: window.location.pathname
      });
    });
  }, {
    threshold: 0.4
  });

  sections.forEach(section => sectionObserver.observe(section));

  // ----------------------------------------
  // CTA CLICK TRACKING
  // ----------------------------------------
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a');
    if (!link) return;

    if (!link.href) return;

    if (
      link.href.includes('#contact') ||
      link.classList.contains('btn') ||
      link.dataset.cta
    ) {
      const section = link.closest('section');

      gtag('event', 'cta_clicked', {
        cta_text: link.textContent.trim().slice(0, 50),
        cta_section: section ? section.id : 'unknown',
        page_type: pageType,
        page_path: window.location.pathname
      });
    }
  });

  // ----------------------------------------
  // PORTFOLIO INTERACTION
  // ----------------------------------------
  document.querySelectorAll('#portfolio img, #portfolio a').forEach(el => {
    el.addEventListener('click', () => {
      gtag('event', 'portfolio_interaction', {
        page_type: pageType,
        page_path: window.location.pathname
      });
    });
  });

  // ----------------------------------------
  // CONTACT FORM TRACKING
  // ----------------------------------------
  const contactForm = document.getElementById('mlp-contact-form');

  if (contactForm) {
    let started = false;

    contactForm.addEventListener('focusin', () => {
      if (started) return;
      started = true;

      gtag('event', 'contact_form_started', {
        page_type: pageType,
        page_path: window.location.pathname
      });
    });

    contactForm.addEventListener('submit', () => {
      gtag('event', 'contact_form_submitted', {
        page_type: pageType,
        page_path: window.location.pathname
      });
    });
  }

})();
