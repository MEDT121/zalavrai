import React from 'react';
import {Composition} from 'remotion';
import {LoginAnimation} from './LoginAnimation';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="LoginAnimation"
        component={LoginAnimation}
        durationInFrames={300}
        fps={30}
        width={390}
        height={844}
      />
    </>
  );
};
