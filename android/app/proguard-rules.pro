# Keep rules para release con R8 (minify) en tresdcal.
#
# El stack no requiere keep rules a nivel app:
#   - purchases_flutter/purchases-android: declaran consumerProguardFiles
#     propias (purchases_flutter/android/proguard-rules.pro + rules del AAR).
#   - drift: codegen, sin reflection en runtime.
#   - pdf: 100% Dart, sin codigo Android.
#   - gal / printing: method channels sin reflection; clases referenciadas
#     por manifest (ej. PrintFileProvider) se mantienen automaticamente.
#
# Regla defensiva generica para dependencias que usen reflection/annotations.
-keepattributes *Annotation*
