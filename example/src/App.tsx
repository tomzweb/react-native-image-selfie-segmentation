import * as React from 'react';
import { Dispatch, SetStateAction, useEffect, useState } from 'react';
import { launchImageLibrary } from 'react-native-image-picker';

import { StyleSheet, View, Text } from 'react-native';
import { replaceBackground } from 'react-native-image-selfie-segmentation';

export default function App() {
  const [result, setResult] = useState<number | undefined>();
  const [inputImageUri, setInputImageUri] = useState<string | undefined>();
  const [backgroundImageUri, setBackgroundImageUri] = useState<
    string | undefined
  >();

  const loadImageLibrary = async (
    setter: Dispatch<SetStateAction<string | undefined>>
  ) => {
    return await launchImageLibrary(
      {
        mediaType: 'photo',
      },
      (result) => {
        const { assets } = result;
        if (assets && assets.length > 0) {
          const { uri } = assets[0];
          setter(uri);
        }
      }
    );
  };

  React.useEffect(() => {
    (async function () {
      try {
        await loadImageLibrary(setInputImageUri);
      } catch (e) {
        console.error(e);
      }
    })();
  }, []);

  useEffect(() => {
    (async function () {
      try {
        if (inputImageUri) {
          await loadImageLibrary(setBackgroundImageUri);
        }
      } catch (e) {
        console.error(e);
      }
    })();
  }, [inputImageUri]);

  useEffect(() => {
    (async function () {
      try {
        if (inputImageUri && backgroundImageUri) {
          await replaceBackground(inputImageUri, backgroundImageUri).then(
            (response) => {
              console.log('RESPONSE FROM IOS', response);
            }
          );
        }
      } catch (e) {
        console.error(e);
      }
    })();
  }, [backgroundImageUri]);

  return (
    <View style={styles.container}>
      <Text>Input: {inputImageUri}</Text>
      <Text>Background: {backgroundImageUri}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
