import React from 'react';
import {Composition} from 'remotion';
import {SchoolSafeLogin} from './LoginAnimation';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="SchoolSafeLogin"
        component={SchoolSafeLogin}
        durationInFrames={360}
        fps={30}
        width={390}
        height={844}
      />
    </>
  );
};
