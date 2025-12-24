'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "51673071e82eac38a09f18c962bc23be",
"assets/AssetManifest.bin.json": "2166d8283cabcf9ef0268609e127ce35",
"assets/assets/images/allthestars.jpg": "ab404f2bbefc78ab923b0a079b9497b2",
"assets/assets/images/artists/a-reece.png": "686b17914b1e513f0f94bb95501ecfc6",
"assets/assets/images/artists/artists.png": "77c4edba1ddc24b67a3803532368f2d5",
"assets/assets/images/artists/Cassper%2520Nyovest%2520Fill%2520Up%2520FNB%2520Station%25201.jpg": "5e4cbedc1094dbafcb52c83230e85ef5",
"assets/assets/images/artists/dea825bd-9dc9-4705-8895-40277d1083c3_rw_1920.jpg": "10ab93571af795191efde9caec9a2148",
"assets/assets/images/artists/emtee.webp": "caf7698bc204743e8d7ff174bebff419",
"assets/assets/images/artists/game.png": "4da0fbe6b493b6f2332c683b7cca7113",
"assets/assets/images/artists/images.jpeg": "c132879089299aa2f3fd68212d4cc00c",
"assets/assets/images/artists/kendrick.png": "3601156853144966c6f929c82bd48715",
"assets/assets/images/artists/kunye.png": "cab41712b7942d9b24b7e1525296f7ea",
"assets/assets/images/artists/lock-in.png": "6b4de3ad007591defbe228d3906f572f",
"assets/assets/images/artists/nasty%2520c.png": "ae2a94a442bdcda51c550e9a40ddd121",
"assets/assets/images/artists/NOTA.png": "9587435645ab7627943e0fcd0d9ae413",
"assets/assets/images/artists/P9-Kabza-de-Small.webp": "22189651cb6d613740b65c9d8d461418",
"assets/assets/images/artists/revenge.jpg": "6e3fd30899434ce1ee76039aa973a8ca",
"assets/assets/images/artists/sony.png": "1604681dbce7aa8cbc3cd57d763c094c",
"assets/assets/images/artists/uni.png": "3b2ede881f6b710d76314df42b55cb75",
"assets/assets/images/gearsh_logo.png": "8a1270837df03da81c1d1a400e88101d",
"assets/assets/images/icons/art.png": "2a3a6b744577b4fa7e14906af39262ad",
"assets/assets/images/icons/calendar.png": "00d1fd0915ecccd71e80a5758e8935a0",
"assets/assets/images/icons/superstar.png": "c0cb0a04b6813a8408c3998653585d0c",
"assets/assets/images/storyboard.png": "c7c6c8b78c82fd22aa4f2cf9d96a4875",
"assets/assets/images/storyboard2.png": "d88d944528d608da42c5ab4b28b07e7b",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "43e99c819eeb87a675ea35350e8c0757",
"assets/NOTICES": "3355277ba738ec5a01b3a45d00ab23d8",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "2e072cc2abd1f00d8fce5fbe74e7ff7b",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "24e2ce1178a52541e94703f1ee58ad19",
"functions/api/forgot-password.js": "908a931d3a093d622c4a430b44d356de",
"functions/api/get_signups.js": "fb2bbc750177befd9799f403fd5bb93d",
"functions/api/login.js": "64636af253b3758218f309c214bb80c3",
"functions/api/reset-password.js": "eb1e2504353b351471badcaa5deef456",
"functions/api/signup.js": "a66a3b9a8eec9031f850a20f955999b8",
"functions/api/social-auth.js": "9879fdafe91c6b37c45e06facc94ef6b",
"functions/api/validate-reset-token.js": "34073a27d7d8977633f93668d852f244",
"icons/Icon-192.png": "740f180ec81d9ee2048b7556b6288fde",
"icons/Icon-512.png": "3aa9d7f5e6818fe4e99de507e945876c",
"icons/Icon-maskable-192.png": "740f180ec81d9ee2048b7556b6288fde",
"icons/Icon-maskable-512.png": "3aa9d7f5e6818fe4e99de507e945876c",
"index.html": "058201572ec8d87919e0872448552e64",
"/": "058201572ec8d87919e0872448552e64",
"main.dart.js": "c17aa60cbfadec6dd6c24302374ecbac",
"manifest.json": "6a5da9eaad781a345b1329b7f328ac9b",
"version.json": "3245676c8847a646195f4ce642996445",
"wrangler.toml": "a7008cec91306f2cb973c0381f170c01",
"_redirects": "d71a0f5ec4666961274b74c5dee458d8"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
