class AppConfig {
  static const _cloudinaryCloudNamePlaceholder = 'YOUR_CLOUD_NAME';
  static const _cloudinaryUploadPresetPlaceholder = 'YOUR_UNSIGNED_PRESET';

  static const cloudinaryCloudName = 'augr5wwt';

  static const cloudinaryUploadPreset = 'vocabquest';

  static bool get cloudinaryConfigured =>
      cloudinaryCloudName.trim().isNotEmpty &&
      cloudinaryUploadPreset.trim().isNotEmpty &&
      cloudinaryCloudName != _cloudinaryCloudNamePlaceholder &&
      cloudinaryUploadPreset != _cloudinaryUploadPresetPlaceholder;
}
