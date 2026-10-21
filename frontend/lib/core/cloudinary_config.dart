// Fallback only - MediaUploadService normally gets the cloud name from the
// backend's signed-upload response (see /media/cloudinary-signature), which
// is the source of truth once CLOUDINARY_* env vars are set there. Kept
// here purely as a defensive default if that field is ever missing.
//
// The old unsigned upload preset this file used to define ('sm77b2fn') is
// NOT used by the app anymore (see media_upload_service.dart for why - an
// unsigned preset embedded in a shipped app is a standing upload-abuse
// vulnerability). That preset still exists on the Cloudinary account and is
// still exploitable by anyone who already has it (e.g. from the
// already-published Play Store APK or this repo's git history) until you
// delete it or switch it to signed mode in the Cloudinary dashboard
// (Settings -> Upload -> Upload presets) - removing it from this file alone
// does not close that hole.
const cloudinaryCloudName = 'dhgiecip6';
