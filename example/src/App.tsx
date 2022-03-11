import * as React from 'react';
import { Dispatch, SetStateAction, useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  Image,
  TouchableOpacity,
  Dimensions,
} from 'react-native';

import { launchImageLibrary } from 'react-native-image-picker';
import { replaceBackground } from 'react-native-image-selfie-segmentation';

const windowWidth = Dimensions.get('window').width;

export default function App() {
  const [loading, setLoading] = useState<boolean>(false);
  const [image, setImage] = useState<string | undefined>();
  const [inputImage, setInputImage] = useState<string | undefined>();
  const [backgroundImage, setBackgroundImage] = useState<string | undefined>();

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

  const onProcessImageHandler = async () => {
    if (inputImage && backgroundImage) {
      setLoading(true);
      await replaceBackground(inputImage, backgroundImage)
        .then((response) => {
          console.log('RESPONSE', response);
          setImage(response);
          setLoading(false);
        })
        .catch((error) => {
          console.log(error);
          setLoading(false);
        });
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.inputContainer}>
        <View style={styles.inputSection}>
          {inputImage ? (
            <Image
              style={styles.inputImage}
              resizeMode="cover"
              source={{ uri: inputImage }}
            />
          ) : (
            <View style={styles.inputImage}>
              <Text style={styles.inputImageText}>+</Text>
            </View>
          )}
          <TouchableOpacity
            style={styles.inputBtn}
            onPress={() => loadImageLibrary(setInputImage)}
          >
            <Text style={styles.inputBtnText}>Add Selfie</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.inputSection}>
          {backgroundImage ? (
            <Image
              style={styles.inputImage}
              resizeMode="cover"
              source={{ uri: backgroundImage }}
            />
          ) : (
            <View style={styles.inputImage}>
              <Text style={styles.inputImageText}>+</Text>
            </View>
          )}
          <TouchableOpacity
            style={styles.inputBtn}
            onPress={() => loadImageLibrary(setBackgroundImage)}
          >
            <Text style={styles.inputBtnText}>Add Background</Text>
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity
        style={
          inputImage && backgroundImage
            ? styles.inputBtn
            : [styles.inputBtn, styles.inputBtnDisabled]
        }
        onPress={onProcessImageHandler}
      >
        <Text style={styles.inputBtnText}>
          {loading ? 'Processing' : 'Process Image'}
        </Text>
      </TouchableOpacity>

      <View style={styles.imageContainer}>
        {image ? (
          <Image
            style={styles.image}
            source={{ uri: image }}
            resizeMode="contain"
          />
        ) : (
          <View style={styles.image}>
            <Text style={styles.inputImageText}>
              {loading ? 'Loading' : 'Press Process Image'}
            </Text>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  inputContainer: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  inputSection: {
    paddingHorizontal: 10,
  },
  inputBtn: {
    padding: 10,
    backgroundColor: '#000000',
    borderRadius: 15,
    alignItems: 'center',
    marginTop: 20,
  },
  inputBtnDisabled: {
    backgroundColor: '#777777',
  },
  inputBtnText: {
    color: '#FFFFFF',
  },
  inputImage: {
    width: (windowWidth - 60) / 2,
    height: (windowWidth - 60) / 2,
    borderRadius: 25,
    backgroundColor: '#EBEBEB',
    justifyContent: 'center',
    alignItems: 'center',
  },
  inputImageText: {
    color: '#000000',
    fontSize: 16,
  },
  imageContainer: {
    flex: 1,
    marginTop: 20,
  },
  image: {
    width: windowWidth - 40,
    height: windowWidth - 40,
    backgroundColor: '#EBEBEB',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 50,
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
