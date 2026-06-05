// ── SchoolSafe Site Data Loader v1.0 ──
// Set SITE_LICENSE_KEY once in your school's fork — never change after deploy
const SITE_LICENSE_KEY = '__SCHOOL_KEY__';

const _SS_CENTRAL = 'https://vcifxatmlgzueavalfks.supabase.co';
const _SS_CKEY = 'sb_publishable_o-S9cAWjPnXvI5r--_OY2g_bKjwYbhV';

function _ssHex(hex, f) {
  const n = parseInt((hex||'#000').slice(1), 16);
  return '#' + [16,8,0].map(ch => {
    const v = (n >> ch) & 255;
    return Math.min(255, Math.max(0, Math.round(f > 0 ? v + (255-v)*f : v*(1+f)))).toString(16).padStart(2,'0');
  }).join('');
}

function _ssApplyTheme(theme, color) {
  const r = document.documentElement;
  const c = color || '#c0962e';
  if (theme === 'light') {
    r.style.setProperty('--emerald', '#1e3a8a');
    r.style.setProperty('--emerald-deep', '#1e40af');
    r.style.setProperty('--emerald-soft', '#1d4ed8');
    r.style.setProperty('--cream', '#f0f4ff');
    r.style.setProperty('--cream-deep', '#dbeafe');
    r.style.setProperty('--paper', '#ffffff');
    r.style.setProperty('--ink', '#1e3a8a');
    r.style.setProperty('--muted', '#64748b');
    r.style.setProperty('--line', 'rgba(30,58,138,.12)');
    r.style.setProperty('--brass', c);
    r.style.setProperty('--brass-deep', _ssHex(c, -0.2));
    r.style.setProperty('--brass-light', _ssHex(c, 0.4));
  } else if (theme === 'custom') {
    r.style.setProperty('--emerald', c);
    r.style.setProperty('--emerald-deep', _ssHex(c, -0.25));
    r.style.setProperty('--emerald-soft', _ssHex(c, -0.1));
    r.style.setProperty('--brass', _ssHex(c, 0.2));
    r.style.setProperty('--brass-deep', c);
    r.style.setProperty('--brass-light', _ssHex(c, 0.5));
  } else {
    // dark — just update accent color
    r.style.setProperty('--brass', c);
    r.style.setProperty('--brass-deep', _ssHex(c, -0.2));
    r.style.setProperty('--brass-light', _ssHex(c, 0.3));
  }
}

function _ssSet(sel, val, attr) {
  document.querySelectorAll(sel).forEach(el => { if (attr) el[attr] = val; else el.textContent = val; });
}

function _ssHydCommon(d) {
  const name    = d.school_name || '';
  const nameEn  = d.school_name_en || '';
  const address = d.address || '';
  const phone   = d.phone || '';
  const email   = d.email || '';
  const logo    = d.logo_url || '';
  const wa      = (d.whatsapp || phone).replace(/\D/g,'');

  if (logo) { _ssSet('.brand img', logo, 'src'); _ssSet('.foot-brand img', logo, 'src'); }
  if (name) { _ssSet('.brand .bn', name); _ssSet('.foot-brand .bn', name); }
  if (nameEn) _ssSet('.brand .bs', nameEn);

  const tb = document.querySelector('.topband .wrap span:first-child');
  if (tb && address) tb.textContent = '📍 ' + address;

  document.querySelectorAll('.topband a[href^="tel"]').forEach(a => {
    if (phone) { a.href = 'tel:' + phone.replace(/\D/g,''); a.textContent = phone; }
  });
  document.querySelectorAll('footer a[href^="tel"]').forEach(a => {
    if (phone) { a.href = 'tel:' + phone.replace(/\D/g,''); a.textContent = phone; }
  });
  document.querySelectorAll('footer a[href^="mailto"]').forEach(a => {
    if (email) { a.href = 'mailto:' + email; a.textContent = email; }
  });
  document.querySelectorAll('a[href^="https://wa.me"]').forEach(a => {
    if (wa) a.href = 'https://wa.me/' + wa;
  });
  const faddr = document.querySelector('.foot-grid > div:first-child > p:last-child');
  if (faddr && address) faddr.innerHTML = '📍 ' + address.replace('—','<br />');

  const yr = new Date().getFullYear();
  document.querySelectorAll('.foot-bottom span:first-child').forEach(el => {
    if (name) el.textContent = '© ' + yr + ' ' + name + (nameEn && nameEn !== name ? ' / ' + nameEn : '') + '. Tous droits réservés.';
  });

  if (name) document.title = document.title.replace(/Complexe Scolaire Le Sage[^—·]*/g, name + ' ').replace(/The Wise School International/g, nameEn || name);

  _ssInjectBranding();
}

function _ssInjectBranding() {
  if (document.getElementById('ss-brand-bar')) return;
  const s = document.createElement('section');
  s.id = 'ss-brand-bar';
  s.style.cssText = 'background:var(--emerald);padding:30px 0;';
  s.innerHTML = '<div class="wrap" style="display:flex;align-items:center;gap:24px;flex-wrap:wrap;justify-content:space-between;">'
    + '<div style="display:flex;align-items:center;gap:14px;">'
    + '<div style="width:50px;height:50px;background:rgba(255,255,255,.12);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:24px;flex-shrink:0">🏫</div>'
    + '<div><div style="font-family:var(--serif,serif);font-size:19px;font-weight:700;color:var(--cream,#f5efe2)">SchoolSafe</div>'
    + '<div style="font-size:11px;color:rgba(255,255,255,.55);letter-spacing:.12em;text-transform:uppercase;margin-top:2px">Système de gestion scolaire</div></div></div>'
    + '<p style="margin:0;color:rgba(255,255,255,.72);font-size:14px;max-width:460px;line-height:1.65;">Ce site est propulsé par <strong style="color:var(--brass-light,#e7c977)">SchoolSafe</strong> — la plateforme intelligente de gestion scolaire pour les établissements d\'Afrique. Présences, paiements, notes, communication parents et sécurité portail, tout en un.</p>'
    + '<a href="site.html" style="background:var(--brass,#c0962e);color:#2a2110;padding:11px 22px;border-radius:4px;font-weight:700;font-size:13px;text-decoration:none;display:inline-block;flex-shrink:0;white-space:nowrap">Découvrir SchoolSafe &#8594;</a>'
    + '</div>';
  const footer = document.querySelector('footer');
  if (footer) footer.parentNode.insertBefore(s, footer);
}

function _ssHydSite(d) {
  if (d.hero_url) {
    const heroImg = document.querySelector('.hero-bg img');
    if (heroImg) heroImg.src = d.hero_url;
  }
  if (d.tagline) {
    const el = document.querySelector('.hero-inner .kicker');
    if (el) el.textContent = d.tagline;
  }
  if (d.about_text) {
    const el = document.querySelector('.about-grid p:first-of-type');
    if (el) el.textContent = d.about_text;
  }
  const stats = d.stats || {};
  if (stats.students) {
    const el = document.querySelector('.stats .stat:first-child .num');
    if (el) el.textContent = stats.students + '+';
  }
  if (stats.teachers) {
    const el = document.querySelector('.stats .stat:nth-child(2) .num');
    if (el) el.textContent = stats.teachers + '+';
  }
  if (stats.classes) {
    const el = document.querySelector('.stats .stat:nth-child(3) .num');
    if (el) el.textContent = stats.classes;
  }
  if (d.founded_year) {
    const tag = document.querySelector('.about .tag .n');
    if (tag) tag.textContent = d.founded_year;
    const tagT = document.querySelector('.about .tag .t');
    if (tagT && d.city) tagT.textContent = 'Fondé · ' + d.city;
  }
  const pillars = d.pillars || [];
  if (pillars.length) {
    const el = document.querySelector('.about-grid .pillars');
    if (el) el.innerHTML = pillars.map(p => '<div class="pillar"><b>' + (p.title||'') + '</b><span>' + (p.desc||'') + '</span></div>').join('');
  }
  // Team hydration (site.html)
  const staff = d.staff || [];
  if (staff.length) {
    const container = document.querySelector('.team .team-grid');
    if (container) {
      container.innerHTML = staff.map(m =>
        '<div class="person">'
        + '<div class="ph">' + (m.photo_url ? '<img src="' + m.photo_url + '" alt="' + (m.name||'') + '" />' : '<div style="width:100%;padding-bottom:100%;background:var(--cream-deep,#ebe2cf)"></div>') + '</div>'
        + '<div class="bd"><div class="role">' + (m.cycle || m.role_label || '') + '</div><h3>' + (m.name||'') + '</h3><p>' + (m.position||'') + '</p></div>'
        + '</div>'
      ).join('');
    }
  }
}

function _ssHydEcole(d) {
  if (d.hero_url) {
    const heroImg = document.querySelector('.page-hero .ph-bg img');
    if (heroImg) heroImg.src = d.hero_url;
  }
  if (d.about_text) {
    const el = document.querySelector('.about-grid p:first-of-type');
    if (el) el.textContent = d.about_text;
  }
  if (d.mission) {
    const el = document.querySelector('.mission-band p');
    if (el) el.innerHTML = '« ' + d.mission + ' »';
  }
  if (d.founded_year) {
    const el = document.querySelector('.about .tag .n');
    if (el) el.textContent = d.founded_year;
    const t = document.querySelector('.about .tag .t');
    if (t && d.city) t.textContent = 'Fondé · ' + d.city;
  }
  const pillars = d.pillars || [];
  if (pillars.length) {
    const el = document.querySelector('.pillars');
    if (el) el.innerHTML = pillars.map(p => '<div class="pillar"><b>' + (p.title||'') + '</b><span>' + (p.desc||'') + '</span></div>').join('');
  }
  const staff = d.staff || [];
  const container = document.getElementById('ecole-staff');
  if (staff.length && container) {
    container.innerHTML = staff.map(m =>
      '<div class="lead-card">'
      + '<div class="ph">' + (m.photo_url ? '<img src="' + m.photo_url + '" alt="' + (m.name||'') + '" />' : '<div style="width:100%;padding-bottom:75%;background:var(--cream-deep,#ebe2cf);display:flex;align-items:center;justify-content:center;font-size:36px">👤</div>') + '<span class="role">' + (m.cycle||m.role_label||'') + '</span></div>'
      + '<div class="bd"><h3>' + (m.name||'') + '</h3><div class="pos">' + (m.position||'') + '</div>' + (m.bio?'<p>'+m.bio+'</p>':'') + (m.quote?'<blockquote>'+m.quote+'</blockquote>':'') + '</div>'
      + '</div>'
    ).join('');
  }
}

function _ssHydGalerie(d) {
  const gallery = d.gallery || [];
  if (gallery.length) {
    const el = document.getElementById('galerie-grid');
    if (el) {
      el.innerHTML = gallery.map((g, i) => {
        const cls = i === 0 ? 'g-big' : (i % 5 === 3 ? 'g-tall' : (i % 7 === 6 ? 'g-wide' : ''));
        return '<figure class="' + cls + '"><img src="' + (g.url||'') + '" alt="' + (g.caption||'Photo') + '" loading="lazy" /><figcaption>' + (g.caption||'') + '</figcaption></figure>';
      }).join('');
    }
  }
  const stats = d.stats || {};
  const numEls = document.querySelectorAll('.excellence .ex-cell .num');
  if (stats.students && numEls[1]) numEls[1].textContent = stats.students;
  if (d.founded_year && numEls[2]) numEls[2].textContent = (new Date().getFullYear() - d.founded_year) + '+';
}

function _ssHydProgrammes(d) {
  if (d.hero_url) {
    const heroImg = document.querySelector('.page-hero .ph-bg img');
    if (heroImg) heroImg.src = d.hero_url;
  }
  const progs = d.programs || {};
  if (progs.maternelle) {
    const el = document.querySelector('#prog-maternelle p:first-of-type');
    if (el) el.textContent = progs.maternelle;
  }
  if (progs.primaire) {
    const el = document.querySelector('#prog-primaire p:first-of-type');
    if (el) el.textContent = progs.primaire;
  }
  if (progs.secondaire) {
    const el = document.querySelector('#prog-secondaire p:first-of-type');
    if (el) el.textContent = progs.secondaire;
  }
}

function _ssHydContact(d) {
  const address = d.address || '';
  const phone   = d.phone || '';
  const email   = d.email || '';
  const wa      = (d.whatsapp || phone).replace(/\D/g,'');
  const schoolName = d.school_name || '';
  const nameEn     = d.school_name_en || '';

  const addrEl = document.querySelector('#contact-address .v');
  if (addrEl && address) addrEl.innerHTML = address.replace('—','<br />');

  const phoneEl = document.querySelector('#contact-phone .v');
  if (phoneEl && phone) phoneEl.innerHTML = '<a href="tel:' + phone.replace(/\D/g,'') + '">' + phone + '</a>';

  const emailEl = document.querySelector('#contact-email .v');
  if (emailEl && email) emailEl.innerHTML = '<a href="mailto:' + email + '">' + email + '</a>';

  document.querySelectorAll('.contact-actions a[href^="https://wa.me"]').forEach(a => { if (wa) a.href = 'https://wa.me/' + wa; });
  document.querySelectorAll('.contact-actions a[href^="tel"]').forEach(a => { if (phone) { a.href = 'tel:' + phone.replace(/\D/g,''); } });

  const infoP = document.querySelector('.enroll-grid .info p');
  if (infoP && schoolName) infoP.textContent = 'Rejoignez ' + schoolName + (nameEn && nameEn !== schoolName ? ' – ' + nameEn : '') + '. Remplissez ce formulaire et notre équipe vous contactera sous 48 heures.';
}

async function _ssFetchAnnouncements() {
  if (!SITE_LICENSE_KEY || SITE_LICENSE_KEY === '__SCHOOL_KEY__') return;
  try {
    const ctrl = new AbortController();
    setTimeout(() => ctrl.abort(), 6000);
    const r = await fetch(
      _SS_CENTRAL + '/rest/v1/school_announcements?license_key=eq.' + encodeURIComponent(SITE_LICENSE_KEY) + '&published=eq.true&order=date.desc&limit=5',
      { headers: { apikey: _SS_CKEY, Authorization: 'Bearer ' + _SS_CKEY }, signal: ctrl.signal }
    );
    if (!r.ok) return;
    const rows = await r.json();
    const el = document.getElementById('site-news-list');
    const section = document.getElementById('site-news-section');
    if (el && rows.length) {
      el.innerHTML = rows.map(n =>
        '<div style="border-bottom:1px solid var(--line);padding:18px 0;">'
        + '<div style="font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--brass-deep);margin-bottom:6px">' + (n.date||'') + '</div>'
        + '<h4 style="font-family:var(--serif);font-size:17px;margin:0 0 8px">' + (n.title||'') + '</h4>'
        + (n.content ? '<p style="color:var(--muted);font-size:15px;margin:0">' + n.content + '</p>' : '')
        + '</div>'
      ).join('');
      if (section) section.style.removeProperty('display');
    }
  } catch(e) {}
}

(async function() {
  if (!SITE_LICENSE_KEY || SITE_LICENSE_KEY === '__SCHOOL_KEY__') return;

  let d;
  try {
    const ctrl = new AbortController();
    setTimeout(() => ctrl.abort(), 8000);
    const r = await fetch(
      _SS_CENTRAL + '/rest/v1/school_sites?license_key=eq.' + encodeURIComponent(SITE_LICENSE_KEY) + '&limit=1',
      { headers: { apikey: _SS_CKEY, Authorization: 'Bearer ' + _SS_CKEY }, signal: ctrl.signal }
    );
    if (!r.ok) return;
    const rows = await r.json();
    if (!rows.length) return;
    d = rows[0];
  } catch(e) { return; }

  _ssApplyTheme(d.theme || 'dark', d.primary_color || '');
  _ssHydCommon(d);

  const page = (location.pathname.split('/').pop() || '').toLowerCase();
  if (!page || page === 'site.html' || page === 'index.html') { _ssHydSite(d); _ssFetchAnnouncements(); }
  else if (page === 'ecole.html')      _ssHydEcole(d);
  else if (page === 'galerie.html')    _ssHydGalerie(d);
  else if (page === 'programmes.html') _ssHydProgrammes(d);
  else if (page === 'contact.html')    _ssHydContact(d);
})();
