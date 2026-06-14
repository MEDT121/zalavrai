import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
  Img,
  staticFile,
  Easing,
  Sequence,
} from 'remotion';
import React from 'react';

const springEase = Easing.bezier(0.16, 1, 0.3, 1);
const bounceEase = Easing.out(Easing.back(1.6));

// ── Background animé ──
const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const pulse = interpolate(Math.sin(frame / 40), [-1, 1], [0, 0.04]);
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(160deg,
          hsl(${240 + frame * 0.3}, 60%, ${14 + pulse * 100}%),
          hsl(${210 + frame * 0.2}, 55%, 10%),
          hsl(${260 + frame * 0.15}, 50%, 8%))`,
      }}
    >
      {[...Array(22)].map((_, i) => {
        const twinkle = interpolate(
          Math.sin((frame + i * 17) / 18),
          [-1, 1],
          [0.15, 0.7]
        );
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              width: 2 + (i % 3),
              height: 2 + (i % 3),
              borderRadius: '50%',
              background: '#fff',
              opacity: twinkle,
              left: `${(i * 43 + 7) % 92}%`,
              top: `${(i * 61 + 11) % 45}%`,
            }}
          />
        );
      })}
    </AbsoluteFill>
  );
};

// ── Fille vue profil (entre de gauche) ──
const GirlSide: React.FC = () => {
  const frame = useCurrentFrame();

  const slideX = interpolate(frame, [0, 55], [-280, 0], {
    extrapolateRight: 'clamp',
    easing: springEase,
  });
  const sway = Math.sin(frame / 7) * 5;
  const bob = Math.abs(Math.sin(frame / 5.5)) * -7;

  const opacity = interpolate(frame, [75, 105], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 72,
        left: '50%',
        transform: `translateX(calc(-50% + ${slideX + sway}px)) translateY(${bob}px)`,
        opacity,
        transformOrigin: 'bottom center',
        zIndex: 3,
      }}
    >
      <Img src={staticFile('girl-side.png')} style={{ height: 330, width: 'auto' }} />
    </div>
  );
};

// ── Fille vue face (révélée au centre) ──
const GirlFront: React.FC = () => {
  const frame = useCurrentFrame();

  const opacity = interpolate(frame, [0, 22], [0, 1], {
    extrapolateRight: 'clamp',
    easing: Easing.ease,
  });
  const scale = interpolate(frame, [0, 28], [0.82, 1], {
    extrapolateRight: 'clamp',
    easing: bounceEase,
  });
  const bob = Math.sin(frame / 22) * 3;

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 72,
        left: '50%',
        transform: `translateX(-50%) scale(${scale}) translateY(${bob}px)`,
        opacity,
        transformOrigin: 'bottom center',
        zIndex: 3,
      }}
    >
      <Img src={staticFile('girl-front.png')} style={{ height: 330, width: 'auto' }} />
    </div>
  );
};

// ── Formulaire de connexion ──
const LoginCard: React.FC = () => {
  const frame = useCurrentFrame();

  const slideY = interpolate(frame, [0, 45], [320, 0], {
    extrapolateRight: 'clamp',
    easing: bounceEase,
  });
  const opacity = interpolate(frame, [0, 18], [0, 1], {
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        position: 'absolute',
        bottom: 50,
        left: '50%',
        transform: `translateX(-50%) translateY(${slideY}px)`,
        opacity,
        width: 272,
        background: 'rgba(255,255,255,0.97)',
        borderRadius: 22,
        padding: '26px 18px',
        boxShadow: '0 20px 60px rgba(0,0,0,0.45)',
        zIndex: 2,
      }}
    >
      <div style={{ textAlign: 'center', marginBottom: 16 }}>
        <div
          style={{
            width: 46,
            height: 46,
            borderRadius: '50%',
            background: '#243a6b',
            margin: '0 auto 9px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: 20,
          }}
        >
          🏫
        </div>
        <div style={{ fontSize: 17, fontWeight: 800, color: '#243a6b', fontFamily: 'sans-serif' }}>
          SchoolSafe
        </div>
        <div style={{ fontSize: 10, color: '#999', marginTop: 3, fontFamily: 'sans-serif' }}>
          Connexion sécurisée
        </div>
      </div>
      <div
        style={{
          background: '#f4f4f4',
          borderRadius: 10,
          padding: '10px 12px',
          marginBottom: 9,
          fontFamily: 'sans-serif',
          fontSize: 12,
          color: '#bbb',
        }}
      >
        👤 Votre nom
      </div>
      <div
        style={{
          background: '#f4f4f4',
          borderRadius: 10,
          padding: '10px 12px',
          marginBottom: 14,
          fontFamily: 'sans-serif',
          fontSize: 12,
          color: '#bbb',
        }}
      >
        🔒 Code PIN
      </div>
      <div
        style={{
          background: '#243a6b',
          borderRadius: 10,
          padding: '11px',
          textAlign: 'center',
          fontFamily: 'sans-serif',
          fontWeight: 700,
          fontSize: 13,
          color: '#fff',
        }}
      >
        Se connecter →
      </div>
    </div>
  );
};

// ── Explosion d'étoiles ──
const StarBurst: React.FC = () => {
  const frame = useCurrentFrame();
  const items = ['⭐', '✨', '💫', '🌟', '⚡', '🎉', '💛', '🎊'];

  return (
    <>
      {items.map((star, i) => {
        const angle = (i / items.length) * Math.PI * 2;
        const dist = interpolate(frame, [0, 22], [0, 95], {
          extrapolateRight: 'clamp',
          easing: Easing.out(Easing.cubic),
        });
        const opacity = interpolate(frame, [0, 5, 18, 30], [0, 1, 1, 0], {
          extrapolateRight: 'clamp',
        });
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              bottom: 390,
              left: '50%',
              transform: `translate(calc(-50% + ${Math.cos(angle) * dist}px), ${Math.sin(angle) * dist}px)`,
              opacity,
              fontSize: 20,
            }}
          >
            {star}
          </div>
        );
      })}
    </>
  );
};

// ── Texte lettre par lettre ──
const WelcomeText: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const text = 'Bienvenue ! 👋';
  const charsVisible = Math.floor(
    interpolate(frame, [0, 38], [0, text.length], {
      extrapolateRight: 'clamp',
      easing: Easing.linear,
    })
  );
  const opacity = interpolate(frame, [55, 70], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        position: 'absolute',
        top: 55,
        width: '100%',
        textAlign: 'center',
        fontFamily: 'sans-serif',
        fontSize: 24,
        fontWeight: 800,
        color: '#fff',
        textShadow: '0 2px 24px rgba(0,0,0,0.6)',
        opacity,
        letterSpacing: 1,
      }}
    >
      {text.slice(0, charsVisible)}
    </div>
  );
};

// ── Composition principale ──
export const LoginAnimation: React.FC = () => {
  const {fps} = useVideoConfig();
  const f = (s: number) => Math.round(s * fps);

  return (
    <AbsoluteFill>
      <Sequence>
        <Background />
      </Sequence>

      {/* Fille de profil entre (0 → 3.5s) */}
      <Sequence from={0} durationInFrames={f(3.5)}>
        <GirlSide />
      </Sequence>

      {/* Formulaire monte (à 2s) */}
      <Sequence from={f(2)}>
        <LoginCard />
      </Sequence>

      {/* Fille de face révélée (à 3s) */}
      <Sequence from={f(3)}>
        <GirlFront />
      </Sequence>

      {/* Explosion étoiles (à 4s, 1.5s) */}
      <Sequence from={f(4)} durationInFrames={f(1.5)}>
        <StarBurst />
      </Sequence>

      {/* Texte Bienvenue (à 4.5s, 2.5s) */}
      <Sequence from={f(4.5)} durationInFrames={f(2.5)} layout="none">
        <WelcomeText />
      </Sequence>
    </AbsoluteFill>
  );
};
