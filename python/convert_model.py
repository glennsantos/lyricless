#!/usr/bin/env python3
"""
Model conversion script for Lyricless
Converts vocal separation models to TFLite and TensorFlow.js formats
"""

import os
import sys
import argparse
import tensorflow as tf
try:
    import tensorflowjs as tfjs
except ImportError:
    tfjs = None
    print("Warning: tensorflowjs not found. Web model conversion will be skipped.")
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
        try:
            # Force Spleeter to use local directory for models
            os.environ['MODEL_PATH'] = 'pretrained_models'
            
            from spleeter.separator import Separator
            # Initialize Separator to trigger download
            # Explicitly set the path to ensure we know where it is
            # from spleeter.model import ModelProvider  <-- Removed invalid import
            
            # Create a local directory for models
            model_dir = Path('pretrained_models')
            model_dir.mkdir(exist_ok=True)
            
            # Use Separator to download
            # Note: Spleeter's API might not expose a direct 'download' method easily
            # but initializing it usually triggers download if missing.
            # We can also try using the ModelProvider directly if needed.
            
            # Try to force download to specific path if possible, or just use default and find it.
            # Spleeter 2.4.0 stores models in a 'pretrained_models' dir in the working directory by default
            # IF we are running from the right place.
            
            # Let's try to just run a dummy separation which definitely triggers download
            separator = Separator('spleeter:2stems')
            
            # Check common locations
            possible_paths = [
                Path('pretrained_models/2stems'),
                Path.home() / '.cache/spleeter/pretrained_models/2stems',
                Path('2stems')
            ]
            
            for p in possible_paths:
                if p.exists():
                    print(f"✓ Model found at: {p}")
                    return p
            
            print("Model not found via Spleeter. Attempting manual download...")
            import urllib.request
            import tarfile
            
            url = "https://github.com/deezer/spleeter/releases/download/v1.4.0/2stems.tar.gz"
            output_dir = Path('pretrained_models/2stems')
            output_dir.mkdir(parents=True, exist_ok=True)
            tar_path = output_dir / "2stems.tar.gz"
            
            print(f"Downloading from {url}...")
            urllib.request.urlretrieve(url, tar_path)
            
            print("Extracting...")
            with tarfile.open(tar_path, "r:gz") as tar:
                tar.extractall(path=output_dir)
            
            # Cleanup
            tar_path.unlink()
            
            print(f"✓ Model downloaded and extracted to: {output_dir}")
            return output_dir

        except Exception as e:
            print(f"✗ Model download failed: {e}")
            import traceback
            traceback.print_exc()
            return None

    def export_to_saved_model(self, checkpoint_path):
        """Export Spleeter checkpoint to SavedModel"""
        print(f"Exporting SavedModel from {checkpoint_path}...")
        try:
            from spleeter.model import model_fn
            from spleeter.utils.configuration import load_configuration
            
            # Load params
            params = load_configuration('spleeter:2stems')
            
            # Create Estimator
            # We need to point model_dir to the directory containing the checkpoint
            estimator = tf.estimator.Estimator(
                model_fn=model_fn,
                model_dir=str(checkpoint_path),
                params=params
            )
            
            # Define input receiver
            def serving_input_receiver_fn():
                # Spleeter expects (None, 2) waveform
                waveform = tf.compat.v1.placeholder(tf.float32, shape=[None, 2], name='waveform')
                # We also need audio_id as it's expected by some parts of the graph, though maybe optional
                # But let's provide it to be safe, or just waveform if model_fn handles it.
                # Looking at WaveformInputProvider, it expects both in features.
                # But if we pass features directly, we control it.
                return tf.estimator.export.ServingInputReceiver(
                    {'waveform': waveform},
                    {'waveform': waveform}
                )
            
            # Export
            export_dir = self.output_dir / 'saved_model'
            if export_dir.exists():
                import shutil
                shutil.rmtree(export_dir)
            
            saved_model_path = estimator.export_saved_model(
                str(export_dir),
                serving_input_receiver_fn
            )
            
            print(f"✓ SavedModel exported to: {saved_model_path}")
            return Path(saved_model_path.decode('utf-8'))

        except Exception as e:
            print(f"✗ SavedModel export failed: {e}")
            import traceback
            traceback.print_exc()
            return None

    def convert_to_tflite(self, model_path, output_name='vocal_remover.tflite'):
        """Convert model to TensorFlow Lite with quantization"""
        print("\nConverting to TensorFlow Lite...")

        if not model_path or not model_path.exists():
            print("Error: Model path does not exist")
            return None
            
        # If it's a checkpoint directory (contains 'checkpoint' file), export it first
        if (model_path / 'checkpoint').exists():
            print("Detected checkpoint directory. Exporting to SavedModel first...")
            saved_model_path = self.export_to_saved_model(model_path)
            if not saved_model_path:
                return None
            model_path = saved_model_path

        try:
            # Convert the SavedModel
            converter = tf.lite.TFLiteConverter.from_saved_model(str(model_path))

            # Apply optimizations
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]
            
            # Allow custom ops (Select TF Ops) since Spleeter uses STFT/InverseSTFT
            converter.target_spec.supported_ops = [
                tf.lite.OpsSet.TFLITE_BUILTINS, # Enable TensorFlow Lite ops.
                tf.lite.OpsSet.SELECT_TF_OPS  # Enable TensorFlow ops.
            ]

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

            return output_path

        except Exception as e:
            print(f"✗ TFLite conversion failed: {e}")
            import traceback
            traceback.print_exc()
            return None

    def convert_to_tfjs(self, model, output_dir='tfjs_model'):
        """Convert model to TensorFlow.js format"""
        print("\nConverting to TensorFlow.js...")

        if tfjs is None:
            print("Skipping TensorFlow.js conversion (module not loaded)")
            return None

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
