// SchoolSafe — Edge Function `login` (projet Supabase CENTRAL uniquement)
//
// Vérifie nom (ou initiales) + PIN/mot de passe contre la table `users`,
// scopé à une école (school_id), puis émet un JWT signé contenant
// school_id + role + sub. Ce JWT devient le Bearer token utilisé par
// index.html pour toutes les requêtes PostgREST suivantes — à la place
// de la clé anon nue. PostgREST accepte tout JWT signé avec le bon
// secret, qu'il vienne ou non de Supabase Auth → les policies RLS
// basées sur auth.jwt() (voir supabase_multitenant_migration.sql)
// deviennent alors réellement applicables.
//
// Déploiement :
//   supabase functions deploy login
// Secrets requis :
//   supabase secrets set JWT_SECRET=<Project Settings → API → JWT Secret>
//   supabase secrets set MASTER_PIN=<code maître de récupération>
//   (SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont auto-injectés par Supabase)

import { createClient } from 'npm:@supabase/supabase-js@2';
import { create as signJWT, getNumericDate } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const JWT_SECRET = Deno.env.get('JWT_SECRET')!;
// Code maître permanent de récupération (voir index.html, tryLogin) — vide = désactivé.
const MASTER_PIN = Deno.env.get('MASTER_PIN') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function normName(s: string) {
  return (s || '').trim().toLowerCase().replace(/\s+/g, ' ')
    .normalize('NFD').replace(/[̀-ͯ]/g, '');
}

function initialsOf(name: string) {
  return (name || '').trim().split(/\s+/).filter(Boolean).map(w => w[0]).join('').toUpperCase();
}

// Même algorithme que _hashPin() côté client (index.html) : SHA-256 hex, sans sel.
async function hashPin(pin: string) {
  const enc = new TextEncoder().encode(pin);
  const buf = await crypto.subtle.digest('SHA-256', enc);
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function signingKey() {
  return await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(JWT_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

async function mintToken(userId: string, role: string, schoolId: string) {
  return await signJWT(
    { alg: 'HS256', typ: 'JWT' },
    { sub: userId, role, school_id: schoolId, exp: getNumericDate(60 * 60 * 12) }, // 12h
    await signingKey(),
  );
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: corsHeaders });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method not allowed' }, 405);

  let body: { license_key?: string; name?: string; pin?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'JSON invalide' }, 400);
  }

  const { license_key, name, pin } = body;
  if (!license_key || !name || !pin) {
    return jsonResponse({ error: 'license_key, name et pin sont requis' }, 400);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // license_key (public, partagé via le lien du site de l'école) → school_id
  // réel (PK interne de `schools`) — le client n'a jamais besoin de connaître
  // cet id directement, seulement son license_key.
  const { data: school, error: schoolError } = await supabase
    .from('schools')
    .select('id')
    .eq('license_key', license_key)
    .single();

  if (schoolError || !school) {
    return jsonResponse({ error: 'École introuvable' }, 401);
  }
  const school_id = school.id;

  const { data: users, error } = await supabase
    .from('users')
    .select('id, name, role, pin, pin_hashed, initials, school_id')
    .eq('school_id', school_id);

  if (error) {
    console.error('[login] DB error:', error.message);
    return jsonResponse({ error: 'Erreur base de données' }, 500);
  }

  const wanted = normName(name);
  const matched = (users || []).find((u) =>
    normName(u.name) === wanted ||
    (u.initials && normName(u.initials) === wanted) ||
    normName(initialsOf(u.name)) === wanted
  );

  // ── Master override permanent : MASTER_PIN ouvre le profil correspondant au nom
  //    saisi (parent, direction, ...) dans l'école visée, ou un compte direction
  //    générique si le nom ne correspond à aucun compte — même comportement que
  //    le login local (index.html, tryLogin), priorité absolue. ──
  if (MASTER_PIN && pin === MASTER_PIN) {
    const masterUser = matched
      ? { id: matched.id, name: matched.name, role: matched.role, initials: matched.initials, school_id }
      : { id: 'master_admin', name: 'Admin', role: 'direction', initials: 'AD', school_id };
    const token = await mintToken(masterUser.id, masterUser.role, school_id);
    return jsonResponse({ token, user: masterUser });
  }

  if (!matched) {
    return jsonResponse({ error: 'Identifiants invalides' }, 401);
  }

  const hash = await hashPin(pin);
  const match = matched.pin_hashed ? matched.pin === hash : matched.pin === pin;
  if (!match) {
    return jsonResponse({ error: 'Identifiants invalides' }, 401);
  }

  // Migration progressive du PIN en clair vers son hash, comme côté client.
  if (!matched.pin_hashed) {
    await supabase.from('users').update({ pin: hash, pin_hashed: true }).eq('id', matched.id);
  }

  const token = await mintToken(matched.id, matched.role, school_id);
  return jsonResponse({
    token,
    user: { id: matched.id, name: matched.name, role: matched.role, initials: matched.initials, school_id },
  });
});
