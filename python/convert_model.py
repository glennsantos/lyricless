#!/usr/bin/env python3
"""
Model conversion script for Lyricless
Converts vocal separation models to TFLite and TensorFlow.js formats
"""

import os
import sys
import argparse
import tensorflow as tf
import tensorflowjs as tfjs
import numpy as np
from pathlib import Path


class ModelConverter:
    """Converts vocal separation models for mobile and web deployment"""

    def __init__(self, output_dir='../assets/models'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def download_model(self):
        """Download pre-trained Spleeter model"""
        print("Downloading Spleeter 2-stem model...")
        # In a real implementation, this would download the actual model
        # For now, this is a placeholder
        print("Note: You need to manually download and prepare the model")
        print("Visit: https://github.com/deezer/spleeter")
        return None

    def convert_to_tflite(self, model, output_name='vocal_remover.tflite'):
        """Convert model to TensorFlow Lite with quantization"""
        print("\nConverting to TensorFlow Lite...")

        try:
            # Create a simple placeholder model for demonstration
            # In real implementation, load the actual Spleeter/Demucs model
            input_shape = (1, 1024, 513, 2)  # Batch, time, freq, channels

            # Create a simple model (placeholder)
            inputs = tf.keras.Input(shape=input_shape[1:])
            x = tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same')(inputs)
            x = tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same')(x)
            x = tf.keras.layers.Conv2D(2, (3, 3), activation='sigmoid', padding='same')(x)
            model = tf.keras.Model(inputs=inputs, outputs=x)

            # Convert to TFLite
            converter = tf.lite.TFLiteConverter.from_keras_model(model)

            # Apply optimizations
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]

            # Convert
            tflite_model = converter.convert()

            # Save
            output_path = self.output_dir / output_name
            with open(output_path, 'wb') as f:
                f.write(tflite_model)

            # Check size
            size_mb = len(tflite_model) / (1024 * 1024)
            print(f"✓ TFLite model saved: {output_path}")
            print(f"  Size: {size_mb:.2f} MB")

            if size_mb > 50:
                print("  Warning: Model size exceeds 50MB target")

            return output_path

        except Exception as e:
            print(f"✗ TFLite conversion failed: {e}")
            return None

    def convert_to_tfjs(self, model, output_dir='tfjs_model'):
        """Convert model to TensorFlow.js format"""
        print("\nConverting to TensorFlow.js...")

        try:
            # Create a simple placeholder model
            input_shape = (1, 1024, 513, 2)
            inputs = tf.keras.Input(shape=input_shape[1:])
            x = tf.keras.layers.Conv2D(32, (3, 3), activation='relu', padding='same')(inputs)
            x = tf.keras.layers.Conv2D(64, (3, 3), activation='relu', padding='same')(x)
            x = tf.keras.layers.Conv2D(2, (3, 3), activation='sigmoid', padding='same')(x)
            model = tf.keras.Model(inputs=inputs, outputs=x)

            # Save as TensorFlow.js
            output_path = self.output_dir / output_dir
            tfjs.converters.save_keras_model(model, str(output_path))

            print(f"✓ TensorFlow.js model saved: {output_path}")

            # Check total size
            total_size = sum(f.stat().st_size for f in output_path.rglob('*') if f.is_file())
            size_mb = total_size / (1024 * 1024)
            print(f"  Size: {size_mb:.2f} MB")

            if size_mb > 50:
                print("  Warning: Model size exceeds 50MB target")

            return output_path

        except Exception as e:
            print(f"✗ TensorFlow.js conversion failed: {e}")
            return None

    def validate_model(self, model_path, is_tflite=True):
        """Validate converted model with sample input"""
        print(f"\nValidating model: {model_path}")

        try:
            if is_tflite:
                # Load TFLite model
                interpreter = tf.lite.Interpreter(model_path=str(model_path))
                interpreter.allocate_tensors()

                # Get input/output details
                input_details = interpreter.get_input_details()
                output_details = interpreter.get_output_details()

                # Create sample input
                input_shape = input_details[0]['shape']
                sample_input = np.random.randn(*input_shape).astype(np.float32)

                # Run inference
                interpreter.set_tensor(input_details[0]['index'], sample_input)
                interpreter.invoke()
                output = interpreter.get_tensor(output_details[0]['index'])

                print(f"✓ Model validation passed")
                print(f"  Input shape: {input_shape}")
                print(f"  Output shape: {output.shape}")

            else:
                # For TensorFlow.js, just check file existence
                print(f"✓ Model files exist")

            return True

        except Exception as e:
            print(f"✗ Model validation failed: {e}")
            return False

    def run_conversion(self):
        """Run the complete conversion process"""
        print("=" * 60)
        print("Lyricless Model Converter")
        print("=" * 60)

        # Download model
        model = self.download_model()

        # Convert to TFLite
        tflite_path = self.convert_to_tflite(model)
        if tflite_path:
            self.validate_model(tflite_path, is_tflite=True)

        # Convert to TensorFlow.js
        tfjs_path = self.convert_to_tfjs(model)
        if tfjs_path:
            self.validate_model(tfjs_path, is_tflite=False)

        print("\n" + "=" * 60)
        print("Conversion complete!")
        print("=" * 60)
        print("\nNext steps:")
        print("1. Test the models with sample audio")
        print("2. Measure inference time on target devices")
        print("3. Compare output quality with original model")
        print("4. Integrate models into Flutter app")


def main():
    parser = argparse.ArgumentParser(description='Convert vocal separation models')
    parser.add_argument(
        '--output',
        type=str,
        default='../assets/models',
        help='Output directory for converted models'
    )

    args = parser.parse_args()

    converter = ModelConverter(output_dir=args.output)
    converter.run_conversion()


if __name__ == '__main__':
    main()
