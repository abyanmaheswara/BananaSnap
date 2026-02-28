"""
============================================================
 BANASNAP - Training Script
 Transfer Learning dengan MobileNetV2
============================================================

 LANGKAH-LANGKAH:
 1. Download dataset dari Kaggle (lihat instruksi di bawah)
 2. Install dependencies: pip install tensorflow pillow numpy scikit-learn matplotlib
 3. Jalankan script ini: python train_model.py
 4. File banana_model.tflite akan digenerate
 5. Copy ke Flutter: assets/model/banana_model.tflite

 DATASET YANG DIREKOMENDASIKAN (Kaggle):
   - "Fruits fresh and rotten for classification"
     https://www.kaggle.com/datasets/sriramr/fruits-fresh-and-rotten-for-classification
   - Ambil folder: freshbanana/ dan rottenbanana/

 STRUKTUR FOLDER DATASET:
   dataset/
   ├── train/
   │   ├── fresh_banana/     (gambar pisang layak)
   │   └── rotten_banana/    (gambar pisang tidak layak)
   └── validation/
       ├── fresh_banana/
       └── rotten_banana/
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt

# ============================================================
#  KONFIGURASI - SESUAIKAN JIKA PERLU
# ============================================================
DATASET_DIR    = './dataset'
OUTPUT_MODEL   = './banana_model.tflite'
OUTPUT_LABELS  = './labels.txt'

IMG_SIZE       = 224       # MobileNetV2 input size
BATCH_SIZE     = 32
EPOCHS_FROZEN  = 3        # Epoch saat base model di-freeze
EPOCHS_FINETUNE = 3       # Epoch saat fine-tuning
LEARNING_RATE  = 0.001
CLASS_NAMES    = ['fresh_banana', 'rotten_banana']  # Sesuaikan nama folder

# ============================================================
#  DATA AUGMENTATION & LOADING
# ============================================================
def create_data_generators():
    print("[DATA] Mempersiapkan data generator...")

    # Augmentasi untuk training (biar model lebih robust)
    train_datagen = ImageDataGenerator(
        rescale=1.0 / 255.0,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.15,
        zoom_range=0.2,
        horizontal_flip=True,
        vertical_flip=True,
        brightness_range=[0.7, 1.3],
        fill_mode='nearest',
    )

    # Validasi hanya rescale, tidak diaugmentasi
    val_datagen = ImageDataGenerator(rescale=1.0 / 255.0)

    train_gen = train_datagen.flow_from_directory(
        os.path.join(DATASET_DIR, 'train'),
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode='binary',  # 2 kelas = binary
        classes=CLASS_NAMES,
        shuffle=True,
    )

    val_gen = val_datagen.flow_from_directory(
        os.path.join(DATASET_DIR, 'validation'),
        target_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        class_mode='binary',
        classes=CLASS_NAMES,
        shuffle=False,
    )

    print(f"[DATA] Training samples  : {train_gen.samples}")
    print(f"[DATA] Validation samples: {val_gen.samples}")
    print(f"[DATA] Class mapping     : {train_gen.class_indices}")

    return train_gen, val_gen


# ============================================================
#  BUAT MODEL (Transfer Learning MobileNetV2)
# ============================================================
def build_model():
    print("\n[MODEL] Membangun model MobileNetV2...")

    # Load MobileNetV2 pre-trained ImageNet, tanpa top layer
    base_model = MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights='imagenet',
    )

    # Freeze semua layer base model dulu
    base_model.trainable = False

    # Bangun model lengkap
    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = base_model(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(256, activation='relu')(x)
    x = layers.Dropout(0.4)(x)
    x = layers.Dense(64, activation='relu')(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(1, activation='sigmoid')(x)  # Binary: 0=fresh, 1=rotten

    model = keras.Model(inputs, outputs)

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss='binary_crossentropy',
        metrics=['accuracy'],
    )

    model.summary()
    return model, base_model


# ============================================================
#  TRAINING
# ============================================================
def train(model, base_model, train_gen, val_gen):
    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor='val_accuracy', patience=5, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss', factor=0.5, patience=3, min_lr=1e-6
        ),
        keras.callbacks.ModelCheckpoint(
            'best_model.h5', monitor='val_accuracy', save_best_only=True
        ),
    ]

    # Hitung class weight otomatis
    total_fresh = train_gen.classes.tolist().count(0)
    total_rotten = train_gen.classes.tolist().count(1)
    if total_fresh > 0 and total_rotten > 0:
        total = total_fresh + total_rotten
        class_weight = {
            0: total / (2 * total_fresh),  # fresh
            1: total / (2 * total_rotten), # rotten
        }
        print(f"\n[TRAIN] Menggunakan Class Weight: {class_weight}")
    else:
        # Fallback manual user based counts if dynamic fetch fails
        total = 381 + 530
        class_weight = {
            0: total / (2 * 381),  
            1: total / (2 * 530),  
        }
        print(f"\n[TRAIN] Fallback MENGGUNAKAN MANUAL Class Weight: {class_weight}")

    # === Fase 1: Training dengan base model frozen ===
    print(f"\n[TRAIN] Fase 1: Training head ({EPOCHS_FROZEN} epoch)...")
    history1 = model.fit(
        train_gen,
        epochs=EPOCHS_FROZEN,
        validation_data=val_gen,
        callbacks=callbacks,
        class_weight=class_weight,
    )

    # === Fase 2: Fine-tuning (unfreeze sebagian layer terakhir) ===
    print(f"\n[TRAIN] Fase 2: Fine-tuning ({EPOCHS_FINETUNE} epoch)...")
    base_model.trainable = True

    # Hanya unfreeze 30 layer terakhir
    fine_tune_at = len(base_model.layers) - 30
    for layer in base_model.layers[:fine_tune_at]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE / 10),
        loss='binary_crossentropy',
        metrics=['accuracy'],
    )

    history2 = model.fit(
        train_gen,
        epochs=EPOCHS_FINETUNE,
        validation_data=val_gen,
        callbacks=callbacks,
        class_weight=class_weight,
    )

    return history1, history2


# ============================================================
#  EVALUASI & PLOT
# ============================================================
def plot_history(history1, history2):
    acc  = history1.history['accuracy']  + history2.history['accuracy']
    val  = history1.history['val_accuracy'] + history2.history['val_accuracy']
    loss = history1.history['loss'] + history2.history['loss']
    vloss= history1.history['val_loss'] + history2.history['val_loss']

    epochs_range = range(len(acc))

    plt.figure(figsize=(14, 5))

    plt.subplot(1, 2, 1)
    plt.plot(epochs_range, acc, label='Train Accuracy')
    plt.plot(epochs_range, val, label='Val Accuracy')
    plt.axvline(x=EPOCHS_FROZEN - 1, color='r', linestyle='--', label='Fine-tune start')
    plt.legend()
    plt.title('Accuracy')
    plt.xlabel('Epoch')

    plt.subplot(1, 2, 2)
    plt.plot(epochs_range, loss, label='Train Loss')
    plt.plot(epochs_range, vloss, label='Val Loss')
    plt.axvline(x=EPOCHS_FROZEN - 1, color='r', linestyle='--', label='Fine-tune start')
    plt.legend()
    plt.title('Loss')
    plt.xlabel('Epoch')

    plt.tight_layout()
    plt.savefig('training_history.png', dpi=150)
    print("[PLOT] Grafik disimpan: training_history.png")
    plt.show()


# ============================================================
#  EXPORT KE TFLITE
# ============================================================
def export_tflite(model):
    print("\n[EXPORT] Mengkonversi ke TFLite...")

    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Optimasi ukuran (quantization)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]  # Float16 quantization

    tflite_model = converter.convert()

    with open(OUTPUT_MODEL, 'wb') as f:
        f.write(tflite_model)

    size_kb = len(tflite_model) / 1024
    print(f"[EXPORT] Model TFLite disimpan: {OUTPUT_MODEL} ({size_kb:.1f} KB)")

    # Simpan labels
    with open(OUTPUT_LABELS, 'w') as f:
        # Index 0 = fresh (LAYAK), Index 1 = rotten (TIDAK_LAYAK)
        f.write("LAYAK\n")
        f.write("TIDAK_LAYAK\n")
    print(f"[EXPORT] Labels disimpan: {OUTPUT_LABELS}")


# ============================================================
#  MAIN
# ============================================================
if __name__ == '__main__':
    print("=" * 55)
    print("  BANASNAP - Model Training")
    print("=" * 55)

    # Cek dataset
    if not os.path.exists(DATASET_DIR):
        print(f"""
[ERROR] Folder dataset tidak ditemukan: {DATASET_DIR}

Silakan download dataset dari Kaggle:
  https://www.kaggle.com/datasets/sriramr/fruits-fresh-and-rotten-for-classification

Lalu atur struktur folder seperti ini:
  dataset/
  |-- train/
  |   |-- fresh_banana/
  |   +-- rotten_banana/
  +-- validation/
      |-- fresh_banana/
      +-- rotten_banana/
""")
        exit(1)

    # Jalankan pipeline
    train_gen, val_gen = create_data_generators()
    model, base_model  = build_model()
    history1, history2 = train(model, base_model, train_gen, val_gen)

    # Evaluasi
    print("\n[EVAL] Evaluasi model pada data validasi...")
    loss, acc = model.evaluate(val_gen)
    print(f"[EVAL] Loss    : {loss:.4f}")
    print(f"[EVAL] Accuracy: {acc * 100:.2f}%")

    plot_history(history1, history2)
    export_tflite(model)

    print("\n✅ SELESAI! Sekarang copy file berikut ke Flutter:")
    print(f"   {OUTPUT_MODEL}  →  flutter_project/assets/model/")
    print(f"   {OUTPUT_LABELS} →  flutter_project/assets/model/")
