<div align="right">
<img align="right" width="25%" src="./docs/demo.gif">
</div>

# react-native-image-selfie-segmentation

Uses [**MLKit Vision** Selfie Segmentation](https://developers.google.com/ml-kit/vision/selfie-segmentation) to combine
a selfie and background image.

## Installation

```sh
npm install react-native-image-selfie-segmentation
cd ios && pod install
```

## Usage

```js
import { replaceBackground } from 'react-native-image-selfie-segmentation';

// ...

const response = await replaceBackground(inputImage, backgroundImage);
```

## Props

| Prop         | Type          | Default | Definition                                                                                                               |
|--------------|---------------|-------|--------------------------------------------------------------------------------------------------------------------------|
| inputImage | Base64 string | `` | Required - The selfie image                                                                                              |
| backgroundImage | Base64 string | `` | Required - The background image <br/><br/>**Notice**: the background must be the same size as the input image, or larger |

## Response

| Response     | Type   | Default | Definition                                                                                      |
|--------------|--------|-------|-------------------------------------------------------------------------------------------------|
| Base64 Image | String | ""  | A base 64 image, containing "data:image/jpeg;base64," and relevant base64 data of the new image |

## Example

```js
const [image, setImage] = useState();
const [inputImage, setInputImageUri] = useState();
const [backgroundImage, setBackgroundImage] = useState();

// ... set the inputImageUri and backgroundImageUri
// ... check the example which uses react-native-image-picker

const onProcessImageHandler = async () => {
  if (inputImage && backgroundImage) {
    await replaceBackground(inputImage, backgroundImage)
      .then((response) => {
        setImage(response);
      })
      .catch((error) => {
        console.log(error);
      });
  }
};

return (
  <>
    <TouchableOpacity onPress={onProcessImageHandler}>
      <Text>Process Image</Text>
    </TouchableOpacity>
    {image && (
      <Image source={{ uri: image }} />
    )}
  </>

);

```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
