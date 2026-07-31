// ══════════════════════════════════════════════════════════════════════════
//  audit-logo.mjs — l'emblème de l'école sur les documents officiels
//
//  Un document qui engage l'école porte son emblème. Sans lui, un bulletin,
//  une fiche de paie ou une liste ENAFEP n'est qu'une feuille imprimée : elle
//  ne prouve rien et une administration peut la refuser.
//
//  Onze documents sur trente-sept en sortaient dépourvus — les deux fiches de
//  paie, les listes ENAFEP et EXÉTAT, la fiche de santé, le kit d'urgence, le
//  rapport SECOPE, le palmarès annuel, le rapport mensuel, le reçu de
//  paiement. Aucun n'était signalé : rien ne le vérifiait.
//
//  L'outil repère chaque appel à `dlPDF`, remonte à la fonction qui le
//  contient, et y cherche `_logoImg` ou `SCHOOL_LOGO`.
//
//  Usage : node tools/audit-logo.mjs
// ══════════════════════════════════════════════════════════════════════════
import fs from 'fs';

const src = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const lignes = src.split('\n');

// `dlPDF` est l'assistant d'impression lui-même, pas un document.
const ASSISTANTS = new Set(['dlPDF']);

const sorties = [];
lignes.forEach((l, i) => {
  if (!/dlPDF\(\s*[A-Za-z_`]/.test(l)) return;
  const nom = /dlPDF\([^,]*,\s*[`'"]([^`'"$]*)/.exec(l);
  sorties.push({ ligne: i + 1, doc: (nom && nom[1]) || l.trim().slice(0, 46) });
});

const debutFonction = (i) => {
  for (let j = i; j >= 0 && j > i - 700; j--)
    if (/^(window\.[A-Za-z_$][\w$]*\s*=|function\s+[A-Za-z_$])/.test(lignes[j])) return j;
  return Math.max(0, i - 200);
};

// `window.machin = …` comme `function machin(…)` : deux formes de déclaration.
// N'en lire qu'une donnait « function » comme nom, et l'assistant d'impression
// n'était jamais reconnu comme tel.
const nomFonction = (ligne) => {
  const m = /^(?:window\.)?([A-Za-z_$][\w$]*)\s*=/.exec(ligne)
         || /^function\s+([A-Za-z_$][\w$]*)/.exec(ligne);
  return m ? m[1] : '?';
};

let sans = 0;
console.log('═══ EMBLÈME DE L\'ÉCOLE SUR LES DOCUMENTS IMPRIMÉS ═══\n');
for (const s of sorties) {
  const d = debutFonction(s.ligne - 1);
  const fn = nomFonction(lignes[d]);
  if (ASSISTANTS.has(fn)) continue;
  const aLogo = /_logoImg|SCHOOL_LOGO|logo_url/.test(lignes.slice(d, s.ligne).join('\n'));
  if (!aLogo) { sans++; console.log(`   ✗ ${fn.padEnd(30)} ${s.doc}   (ligne ${s.ligne})`); }
}

const total = sorties.filter(s => !ASSISTANTS.has(nomFonction(lignes[debutFonction(s.ligne - 1)]))).length;

console.log(sans
  ? `\n✗ ${sans} document(s) sur ${total} sans emblème — ajouter \`\${_logoImg(60)}\` à l'en-tête`
  : `\n✓ Les ${total} documents officiels portent l'emblème de l'école`);
process.exit(sans ? 1 : 0);
