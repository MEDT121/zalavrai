// ── Accès non gardés à DB.<table> ────────────────────────────────────────
// `DB.students.filter(...)` plante si la table n'a pas encore été chargée —
// écran blanc, application inutilisable. `(DB.students||[])` ne plante pas.
// Les tables sont initialisées à [] au démarrage, mais loadFromSupabase peut
// les remplacer par autre chose, et un cache chiffré ancien peut ne pas les
// contenir du tout.
import { readFileSync } from 'fs';
import { parse } from 'acorn';
import { simple } from 'acorn-walk';

const html = readFileSync('index.html', 'utf8');
const blocks = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)];
let src = '', offset = [];
for (const b of blocks) {
  offset.push({ start: src.length, line: html.slice(0, b.index).split('\n').length });
  src += b[1] + '\n;\n';
}
const ligneDe = (pos) => {
  let o = offset[0];
  for (const x of offset) if (x.start <= pos) o = x;
  return o.line + src.slice(o.start, pos).split('\n').length - 1;
};

const ast = parse(src, { ecmaVersion: 2022, locations: false });
const trouve = [];
simple(ast, {
  MemberExpression(node) {
    // cible : DB.<table>.<methode>  — sans parenthèse de garde
    const obj = node.object;
    if (!obj || obj.type !== 'MemberExpression') return;
    if (obj.object?.type !== 'Identifier' || obj.object.name !== 'DB') return;
    if (obj.property?.type !== 'Identifier') return;
    const table = obj.property.name;
    const meth = node.property?.name;
    if (!meth) return;
    // seules les méthodes de tableau nous intéressent
    if (!['filter','map','find','findIndex','forEach','some','every','reduce',
          'slice','sort','push','unshift','includes','length','indexOf','splice','join','concat'].includes(meth)) return;
    trouve.push({ table, meth, pos: node.start });
  },
});

const parTable = new Map();
for (const t of trouve) {
  if (!parTable.has(t.table)) parTable.set(t.table, []);
  parTable.get(t.table).push(t);
}
console.log('═══ ACCÈS NON GARDÉS À DB.<table> ═══\n');
let total = 0;
for (const [table, l] of [...parTable].sort((a, b) => b[1].length - a[1].length)) {
  total += l.length;
  const lignes = [...new Set(l.map(x => ligneDe(x.pos)))].sort((a, b) => a - b);
  console.log(`${table.padEnd(24)} ${String(l.length).padStart(3)}  lignes ${lignes.slice(0, 10).join(', ')}${lignes.length > 10 ? ` … +${lignes.length - 10}` : ''}`);
}
console.log(`\n${total} accès non gardés sur ${parTable.size} table(s)`);
