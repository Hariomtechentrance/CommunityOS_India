// Background push handler for emergency SOS alerts - shows an OS-level
// notification when the app/tab is fully closed. Config matches
// lib/firebase_options.dart (already committed as non-secret, same as the
// Maps browser key).
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBTgCFvXtgTHE80uFhHPxok94OsiLB321w',
  authDomain: 'community-os-india.firebaseapp.com',
  projectId: 'community-os-india',
  storageBucket: 'community-os-india.firebasestorage.app',
  messagingSenderId: '49536469012',
  appId: '1:49536469012:web:45131259da38909064bf01',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Emergency alert';
  const body = payload.notification?.body ?? 'Someone nearby needs help.';
  self.registration.showNotification(title, {
    body,
    icon: 'icons/Icon-192.png',
    tag: payload.data?.postId,
  });
});
