/// Fill these in with the values from your Cloudinary dashboard.
///
/// Only the cloud name and an UNSIGNED upload preset go in the app.
/// Never put your Cloudinary API secret in app code.
class AppConfig {
  static const _cloudinaryCloudNamePlaceholder = 'YOUR_CLOUD_NAME';
  static const _cloudinaryUploadPresetPlaceholder = 'YOUR_UNSIGNED_PRESET';

  /// Cloudinary dashboard -> top-left, "Cloud name".
  static const cloudinaryCloudName = 'augr5wwt';

  /// Cloudinary -> Settings -> Upload -> Upload presets -> Signing mode: Unsigned.
  static const cloudinaryUploadPreset = 'vocabquest';

  static bool get cloudinaryConfigured =>
      cloudinaryCloudName.trim().isNotEmpty &&
      cloudinaryUploadPreset.trim().isNotEmpty &&
      cloudinaryCloudName != _cloudinaryCloudNamePlaceholder &&
      cloudinaryUploadPreset != _cloudinaryUploadPresetPlaceholder;
}
