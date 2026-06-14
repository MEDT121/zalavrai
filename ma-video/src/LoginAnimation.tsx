import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  Easing,
} from 'remotion';

// ── Dimensions ──
const W      = 390;
const H      = 844;
const CARD_W = 280;
const CARD_H = 345;
const CARD_X = (W - CARD_W) / 2;          // 55
const CARD_Y = (H - CARD_H) / 2 - 10;    // ~237

const COLS = 10;
const ROWS = 12;
const CW = CARD_W / COLS;   // 28
const CH = CARD_H / ROWS;   // ~28.75

const fps = 30;
const f   = (s: number) => Math.round(s * fps);

// ── Seeded pseudo-random (0..1) ──
const rnd = (seed: number): number => {
  const x = Math.sin(seed * 9301 + 49297) * 233280;
  return x - Math.floor(x);
};

// ── Cube colors — mimique le contenu de la carte ──
const cubeColor = (c: number, r: number): string => {
  if (r <= 1 && c >= 3 && c <= 6) return '#1e3a8a'; // logo
  if (r >= 2 && r <= 3)           return '#dde5f7'; // titre
  if (r >= 4 && r <= 5)           return '#eef0fa'; // champ 1
  if (r >= 6 && r <= 7)           return '#eef0fa'; // champ 2
  if (r >= 9 && r <= 10)          return '#2d52b0'; // bouton
  return '#f6f8ff';                                   // fond carte
};

// ── Carte de connexion ──
const LoginCard: React.FC<{ extra?: React.CSSProperties }> = ({ extra }) => (
  <div style={{
    position: 'absolute',
    left: CARD_X,
    top: CARD_Y,
    width: CARD_W,
    background: 'rgba(255,255,255,0.97)',
    borderRadius: 22,
    padding: '26px 22px 24px',
    boxShadow: '0 24px 80px rgba(0,0,0,0.55)',
    ...extra,
  }}>
    <div style={{ textAlign: 'center', marginBottom: 16 }}>
      <div style={{
        width: 50, height: 50, borderRadius: '50%', background: '#1e3a8a',
        margin: '0 auto 10px', display: 'flex', alignItems: 'center',
        justifyContent: 'center', fontSize: 22,
      }}>🏫</div>
      <div style={{ fontSize: 17, fontWeight: 800, color: '#1e3a8a', fontFamily: 'sans-serif' }}>
        SchoolSafe
      </div>
      <div style={{ fontSize: 11, color: '#aaa', marginTop: 3, fontFamily: 'sans-serif' }}>
        Connexion sécurisée
      </div>
    </div>
    <div style={{ background: '#f2f4fb', borderRadius: 10, padding: '11px 14px', marginBottom: 10, fontFamily: 'sans-serif', fontSize: 13, color: '#bbb' }}>
      👤 Votre nom
    </div>
    <div style={{ background: '#f2f4fb', borderRadius: 10, padding: '11px 14px', marginBottom: 16, fontFamily: 'sans-serif', fontSize: 13, color: '#bbb' }}>
      🔒 Code PIN
    </div>
    <div style={{ background: '#1e3a8a', borderRadius: 10, padding: '13px', textAlign: 'center', fontFamily: 'sans-serif', fontWeight: 700, fontSize: 14, color: '#fff' }}>
      Se connecter →
    </div>
  </div>
);

// ── Composition principale ──
export const SchoolSafeLogin: React.FC = () => {
  const frame = useCurrentFrame();

  // ── Timings ──
  const T_ENTER       = f(1.0);   // carte en place
  const T_SHAKE_START = f(1.5);   // tremblement
  const T_EXPLODE     = f(2.0);   // explosion
  const T_PEAK        = f(4.5);   // cubes au maximum
  const T_REASSEMBLE  = f(7.5);   // reconstruction terminée
  const T_GLOW_PEAK   = f(8.5);   // pic du halo
  const T_IDLE        = f(9.2);   // respiration idle

  const inExplosion = frame >= T_EXPLODE && frame < T_REASSEMBLE;
  const showCard    = frame < T_EXPLODE || frame >= T_REASSEMBLE;

  // ── Entrée de la carte (glisse du haut avec rebond) ──
  const entranceY = interpolate(frame, [0, T_ENTER], [-H * 0.75, 0], {
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.back(1.5)),
  });

  // ── Tremblement pré-explosion ──
  const shakeIntensity = interpolate(frame, [T_SHAKE_START, T_EXPLODE], [0, 1], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const shake = frame >= T_SHAKE_START && frame < T_EXPLODE
    ? Math.sin(frame * 2.2) * shakeIntensity * 6
    : 0;

  // ── Flash blanc juste avant l'explosion ──
  const flash = interpolate(frame, [f(1.95), f(2.0), f(2.08)], [0, 1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });

  // ── Halo bleu après reconstruction ──
  const glow = interpolate(
    frame,
    [T_REASSEMBLE, T_GLOW_PEAK, f(11), f(12)],
    [0, 1, 0.35, 0.35],
    { extrapolateRight: 'clamp' }
  );

  // ── Pulsation idle ──
  const pulse = frame >= T_IDLE
    ? Math.sin((frame - T_IDLE) / 24) * 0.012
    : 0;

  // ── Fond animé ──
  const hue = interpolate(frame, [0, 360], [222, 250], { extrapolateRight: 'clamp' });

  // ── Cubes ──
  const cubes: React.ReactNode[] = [];
  if (inExplosion) {
    const cardCX = CARD_X + CARD_W / 2;
    const cardCY = CARD_Y + CARD_H / 2;

    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        const idx = r * COLS + c;

        // Position "maison" du cube (carte assemblée)
        const hx = CARD_X + c * CW;
        const hy = CARD_Y + r * CH;

        // Direction d'explosion (centrifuge + variance aléatoire)
        const baseAngle = Math.atan2(hy - cardCY, hx - cardCX);
        const angle     = baseAngle + (rnd(idx * 7 + 1) - 0.5) * 1.6;
        const speed     = 110 + rnd(idx * 3 + 1) * 290;
        const gravity   = 40  + rnd(idx * 5 + 2) * 200;
        const spin      = (rnd(idx * 3 + 4) - 0.5) * 700;

        // Position au pic de l'explosion
        const peakX = hx + Math.cos(angle) * speed;
        const peakY = hy + Math.sin(angle) * speed + gravity;

        let cx: number, cy: number, rot: number;

        if (frame < T_PEAK) {
          // Phase explosion : maison → pic
          const p = interpolate(frame, [T_EXPLODE, T_PEAK], [0, 1], {
            extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
            easing: Easing.out(Easing.cubic),
          });
          cx  = hx + (peakX - hx) * p;
          cy  = hy + (peakY - hy) * p;
          rot = spin * p;
        } else {
          // Phase reconstruction : pic → maison
          const p = interpolate(frame, [T_PEAK, T_REASSEMBLE], [0, 1], {
            extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
            easing: Easing.out(Easing.back(0.85)),
          });
          cx  = peakX + (hx - peakX) * p;
          cy  = peakY + (hy - peakY) * p;
          rot = spin * (1 - p);
        }

        cubes.push(
          <div key={idx} style={{
            position: 'absolute',
            left: cx,
            top: cy,
            width: CW - 1.5,
            height: CH - 1.5,
            background: cubeColor(c, r),
            transform: `rotate(${rot}deg)`,
            borderRadius: 3,
            boxShadow: '0 3px 14px rgba(0,0,0,0.45)',
          }} />
        );
      }
    }
  }

  return (
    <AbsoluteFill style={{
      background: `linear-gradient(160deg, hsl(${hue},62%,9%) 0%, hsl(${hue + 22},52%,6%) 100%)`,
    }}>

      {/* Étoiles */}
      {Array.from({ length: 32 }, (_, i) => {
        const op = interpolate(Math.sin(frame * 0.05 + i * 1.1), [-1, 1], [0.08, 0.55]);
        return (
          <div key={i} style={{
            position: 'absolute',
            width: 1 + (i % 2), height: 1 + (i % 2),
            borderRadius: '50%', background: '#fff', opacity: op,
            left: `${(i * 43 + 7) % 95}%`,
            top: `${(i * 67 + 11) % 48}%`,
          }} />
        );
      })}

      {/* Carte HTML (avant explosion + après reconstruction) */}
      {showCard && (
        <LoginCard extra={{
          transform: `translateY(${entranceY}px) translateX(${shake}px) scale(${1 + pulse})`,
          boxShadow: `0 24px 80px rgba(0,0,0,0.55), 0 0 ${65 * glow}px rgba(74,144,217,${glow * 0.85})`,
        }} />
      )}

      {/* Cubes (pendant explosion et reconstruction) */}
      {cubes}

      {/* Flash blanc pré-explosion */}
      {flash > 0 && (
        <div style={{
          position: 'absolute', inset: 0,
          background: `rgba(255,255,255,${flash * 0.65})`,
          pointerEvents: 'none',
        }} />
      )}

    </AbsoluteFill>
  );
};
