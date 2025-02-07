Fixes:
1) Cloud function: Remove trigger on blob data (matches search file structure rn)
2) Fix thumbnail generation bug too wide: https://chatgpt.com/c/67a3781e-aa9c-8004-89b4-90c420342044

Beautification
1) Welcome flow, showcasing features
2) Profile page (edit profile) (done)
3) UI changes

Optimizations
1) 
2) Optimize videos
  a) Video compression
  b) Video caching (+1 prefetch done)
  c) Lower resolution/ multiresolution
  d) Streaming / chunking (hls done)
3) Feed algorithm

Features
1) Explore page
2) Daily resets of cravings / manual test reset button
3) fix the like/heart button in the feed to implement tracking in users subcollection

Security
1) Appcheck
W/StorageUtil(28224): Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
2) Serious auth (phone number verification)
3) Upload file size limits

Thursday 2/6
1) Video optimizations: Client-side prefetching (done)
2) Video optimizations: HLS streaming (done) -> seems decently fast, maybe don't strictly need compression rn. Could increase cache size.
3) Misc: profile video tab, feed profile icon, profile edit profile pics (done)

Friday 2/7
0) Fix Profile video bugs: (thumbnail stretched, videos should be same as feed ui)
1) Feature, delete videos
2) iOs build? Android production build?
3) Firebase beta distributions

Beyond
1) Feed algorithm
2) Explore page / AI features