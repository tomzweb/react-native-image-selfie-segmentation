import * as React from 'react';
import { Dispatch, SetStateAction, useState } from 'react';
import { launchImageLibrary } from 'react-native-image-picker';

import { StyleSheet, View, Text, Image, Button } from 'react-native';
import { replaceBackground } from 'react-native-image-selfie-segmentation';

export default function App() {
  const [image, setImage] = useState<string | undefined>();
  const [inputImageUri, setInputImageUri] = useState<string | undefined>();
  const [backgroundImageUri, setBackgroundImageUri] = useState<
    string | undefined
  >();

  const loadImageLibrary = async (
    setter: Dispatch<SetStateAction<string | undefined>>
  ) => {
    console.log('LOADING IMAGE LIBRARY');
    return await launchImageLibrary(
      {
        mediaType: 'photo',
        includeBase64: true,
      },
      (result) => {
        const { assets } = result;
        if (assets && assets.length > 0) {
          const { base64 } = assets[0];
          setter(base64);
        }
      }
    );
  };

  const onProcessImageHandler = async () => {
    if (inputImageUri && backgroundImageUri) {
      console.log('BEGIN PROCESSING IMAGE');
      await replaceBackground(inputImageUri, backgroundImageUri).then(
        (response) => {
          console.log('IMAGE PROCESSED');
          setImage(response);
        }
      );
    }
  };

  return (
    <View style={styles.container}>
      {image && (
        <Image
          style={styles.image}
          source={{ uri: image }}
          resizeMethod="auto"
          resizeMode="cover"
        />
      )}
      <Button
        title={'Load Input Image'}
        onPress={() => loadImageLibrary(setInputImageUri)}
      />
      <Text>Input: {inputImageUri ? 'Loaded' : 'Pending'}</Text>
      <Button
        title={'Load Background Image'}
        onPress={() => loadImageLibrary(setBackgroundImageUri)}
      />
      <Text>Background: {backgroundImageUri ? 'Loaded' : 'Pending'}</Text>
      {inputImageUri && backgroundImageUri && (
        <Button title={'Process Image'} onPress={onProcessImageHandler} />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: {
    width: '100%',
    height: 400,
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
